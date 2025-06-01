%% Analysis with the Coca-cola VS Pepsi dataset
clear; 
clc;
close all;
format long

%% Question H: Energy Sector Pairs Trading Strategy (XLE vs XOP)
% This section analyzes a pairs trading strategy between XLE (Energy Select Sector SPDR) 
% and XOP (SPDR S&P Oil & Gas Exploration & Production ETF) using:
% 1. OU process calibration
% 2. Bootstrap confidence intervals
% 3. Optimal trading band calculation
% 4. Out-of-sample performance testing
% -------------------------------------------------------------------------

% 1. Data Import and Preparation
fprintf('=================================== Question H ===================================\n');
tic;
% Import Excel data with custom options
opts = detectImportOptions('KO_PEP.xlsx', 'Sheet', 'KO');
opts.DataRange = 'A4'; % Skip first 3 header rows, start from row 4
T = readtable('KO_PEP.xlsx', opts);

% Define data columns (timestamp, bid/ask pairs)
column_timestamp = 1;      % Column containing timestamps
columnXLE = [4, 3];        % XLE [Bid, Ask] columns  
columnXOP = [10, 9];       % XOP [Bid, Ask] columns

% Currency conversion factors (adjust for price scale differences)
converterXLE = 1;          % No conversion needed for XLE
converterXOP = 0.5;        % Adjust XOP prices by 50%
flag = true;               % Enable verbose output during extraction

% Extract mid-prices and log-returns from bid/ask data
[Rt, timestamp, mid_XLE, mid_XOP, low_XLE, low_XOP, high_XLE, high_XOP] = ...
    extractionBidAskMidLogReturn(T, column_timestamp, columnXLE, columnXOP, ...
                                converterXLE, converterXOP, flag);

% 2. Data Cleaning and Period Splitting
InputFormat = 'yyyy-MM-dd HH:mm:ss'; 
splitTime = calmonths(45); % 45-month in-sample period (~3.75 years)
verbose = true;            % Show processing details

% Remove outliers from log-returns using IQR method
[Rt_filtered, time_filtered, ~] = removeOutliers(Rt, timestamp, InputFormat, verbose);

% Split into in-sample (IS) and out-of-sample (OS) periods
[Rt_IS_filtered, ~, Rt_OS_filtered, ~] = ...
    IS_OS_split(Rt_filtered, time_filtered, splitTime, verbose);

% 3. OU Process Calibration
% Calculate time increment between observations (in years)
proportion = computeTimeProportion(timestamp(1), splitTime, timestamp(end));
deltaT = proportion / length(Rt_IS_filtered); 

% Calibrate OU parameters (η, κ, σ) using maximum likelihood
[eta_hat, k_hat, sigma_hat] = calibration(Rt_IS_filtered, deltaT);

% 4. Parameter Uncertainty Analysis
n_sim = 1e2;       % Number of bootstrap simulations
rng(42);           % Set random seed for reproducibility

% Generate bootstrap distributions of parameters
[sigma_hat_vector, k_hat_vector, eta_hat_vector] = ...
    simulation(Rt_IS_filtered, n_sim, deltaT, eta_hat, k_hat, sigma_hat);

% Calculate 95% confidence intervals
alpha = 0.05;
ci_k = prctile(k_hat_vector, [alpha*50, 100-alpha*50]);
ci_sigma = prctile(sigma_hat_vector, [alpha*50, 100-alpha*50]);
ci_eta = prctile(eta_hat_vector, [alpha*50, 100-alpha*50]);

% 5. Parameter Distribution Visualization
% Create consistent figure style
figOpts = {'Color', 'white', 'Position', [100 100 800 400]};
fontOpts = {'FontSize', 11, 'FontWeight', 'bold'};
lineOpts = {'LineWidth', 2, 'Color', 'r'};

% k_hat distribution
figure(figOpts{:});
histogram(k_hat_vector, 100, 'Normalization', 'pdf', ...
          'FaceColor', [0.3 0.6 0.9], 'EdgeColor', 'none');
hold on;
xline(ci_k(1), lineOpts{:}, 'Label', sprintf('%2.1f%%', alpha*50), ...
    'LabelHorizontalAlignment', 'left');
xline(ci_k(2), lineOpts{:}, 'Label', sprintf('%2.1f%%', 100-alpha*50), ...
    'LabelHorizontalAlignment', 'right');
title('Distribution of Mean-Reversion Rate (\kappa)', fontOpts{:});
xlabel('\kappa (1/year)'); ylabel('Probability Density');
grid on; box off;

% sigma_hat distribution
figure(figOpts{:});
histogram(sigma_hat_vector, 100, 'Normalization', 'pdf', ...
          'FaceColor', [0.9 0.5 0.2], 'EdgeColor', 'none');
hold on;
xline(ci_sigma(1), lineOpts{:});
xline(ci_sigma(2), lineOpts{:});
title('Distribution of Volatility (\sigma)', fontOpts{:});
xlabel('\sigma (annualized)'); ylabel('Probability Density');
grid on; box off;

% eta_hat distribution
figure(figOpts{:});
histogram(eta_hat_vector, 100, 'Normalization', 'pdf', ...
          'FaceColor', [0.4 0.8 0.4], 'EdgeColor', 'none');
hold on;
xline(ci_eta(1), lineOpts{:});
xline(ci_eta(2), lineOpts{:});
title('Distribution of Long-Term Mean (\eta)', fontOpts{:});
xlabel('\eta (log-return units)'); ylabel('Probability Density');
grid on; box off;

% 6. Print Calibration Results
fprintf('=== Maximum Likelihood Estimates ===\n');
fprintf('%-12s: %.6f (1/year)\n', 'κ (kappa)', k_hat);
fprintf('%-12s: %.6f\n', 'η (eta)', eta_hat);
fprintf('%-12s: %.6f\n\n', 'σ (sigma)', sigma_hat);

fprintf('=== 95%% Confidence Intervals ===\n');
fprintf('%-12s: [%.6f, %.6f]\n', 'κ interval', ci_k(1), ci_k(2));
fprintf('%-12s: [%.6f, %.6f]\n', 'η interval', ci_eta(1), ci_eta(2));
fprintf('%-12s: [%.6f, %.6f]\n', 'σ interval', ci_sigma(1), ci_sigma(2));

% 7. Optimal Trading Strategy
f = 1;          % No leverage
l = -1.960;     % 2.5% quantile stop-loss 
c_vals = linspace(0.001, 1.00, 100); % Transaction cost range
bidAskSpread = 0.01; % 1% average bid-ask spread

% Calculate optimal trading bands
[d_vals, u_vals, d_star, u_star, c_bar, SIGMA, theta, expected_C] = ...
    optimizedTradingStrategy(mid_XLE, mid_XOP, sigma_hat, k_hat, ...
                            l, f, c_vals, bidAskSpread);

% 8. Trading Band Visualization
figure(figOpts{:});
plot(c_vals, -d_vals, 'r-', 'LineWidth', 2); 
hold on;
plot(c_vals, u_vals, 'b--', 'LineWidth', 2);
xline(c_bar, 'g:', 'LineWidth', 2.5, 'Label', sprintf('c_{bar} = %.3f', c_bar));

% Mark optimal point
plot([c_bar, c_bar], [-d_star, u_star], 'o', ...
     'MarkerSize', 10, 'MarkerFaceColor', [0 0.8 0.8], ...
     'MarkerEdgeColor', 'k');

% Formatting
xlabel('Transaction Cost (c) in σ units', 'FontSize', 11);
ylabel('Optimal Trading Bands (σ units)', 'FontSize', 11);
title('Optimal Trading Bands vs. Transaction Cost', fontOpts{:});
legend({'|d^*| (Entry Band)', 'u^* (Exit Band)'}, 'Location', 'northwest');
grid on;
set(gca, 'Layer', 'top');

% 9. Out-of-Sample Performance
n = 1;                  % No annualization 
w0 = 1;                 % Initial wealth = 1
scaling_factor = 1;     % Return scaling
verbose = true;         % Show detailed output
verbose_optimizedReturned = false; % Suppress optimization details

% Test strategy on out-of-sample data
[X_OS, mu_theoritical, ann_pct_return] = ...
    long_run_futures(Rt_OS_filtered, eta_hat, theta, SIGMA, ...
                    u_star, d_star, l, c_bar, f, w0, scaling_factor, ...
                    verbose, verbose_optimizedReturned);

elapsedTimeH = toc;
fprintf('\n=== Out-of-Sample Performance ===\n');
fprintf('Expected Annual Return: %.2f%%\n', mu_theoritical*100);
fprintf('Realized Return: %.2f%%\n', ann_pct_return*100);
fprintf('Total execution time question H: %.4f seconds\n\n', elapsedTimeH);