clear; clc;
close all
format long

%% Question A - Optimal Trading Bands Analysis
fprintf('=================================== Question A ===================================\n');
% This section performs the optimization of trading bands for a statistical arbitrage strategy
% using Ornstein-Uhlenbeck (OU) process parameters with stop-loss and transaction costs.
%
% Methodology:
% 1. Takes calibrated OU process parameters (theta, sigma)
% 2. Computes optimal trading bands (d,u) for a range of transaction costs
% 3. Visualizes the relationship between costs and optimal bands
% 4. Demonstrates strategy feasibility under different cost regimes

tic;  % Start timer to measure execution performance

% === OU Process Parameters ===
theta = 0.041;        % Mean-reversion time scale (1/kappa) in years
                      % Indicates spreads revert to mean in ~1/0.041 ≈ 24.4 days
sigma = 0.0147;       % Stationary standard deviation (sigma/sqrt(2*kappa))
                      % Annualized volatility of the spread process
                      % Critical for determining trading band distances

% === Stop-loss Level ===
l = -1.960;           % Stop-loss threshold in standard deviation units
                      % Corresponds to 2.5% one-tailed significance (Z=-1.96)
                      % Chosen to limit downside while allowing mean-reversion

% === Transaction Cost Range ===
c_vals = linspace(0.001, 0.75, 100);  % Range of normalized transaction costs
                                      % Expressed as fractions of sigma
                                      % 0.001: Near frictionless market
                                      % 0.75: Upper practical limit before
                                      % strategy becomes unprofitable

% === Strategy Leverage ===
f = 1;                % Capital allocation factor (1 = 100% invested)
                      % Maintained at 1 for unlevered baseline analysis
                      % Could be increased for leveraged strategies

% === Optimize Trading Bands ===
[d_vals, u_vals] = maximize_mu(c_vals, l, sigma, theta, f);
% Computes:
%   d_vals: Vector of optimal entry points (below mean)
%            where spread is "too low" and likely to revert up
%   u_vals: Vector of optimal exit points (above mean)
%            where spread is "too high" and likely to revert down
% For each c in c_vals, finds (d,u) that maximize expected return μ

% === Visualization ===
flag = true;       % Controls plot display mode
                   % true = basic plot without critical cost markers
                   % false = enhanced plot with profitability thresholds
plot_BANDSvsCOST(c_vals, d_vals, u_vals, flag);
% Generates:
% - Curve of d*(c) showing how entry points vary with costs
% - Curve of u*(c) showing how exit points vary with costs
% - Demonstrates the cost-band tradeoff critical for strategy design

elapsedTimeA = toc;
fprintf('Execution time for Question A: %.4f seconds\n', elapsedTimeA);

%% Question B – Inference from Historical Data (HO-LGO)
fprintf('=================================== Question B ===================================\n');
tic;

% === Step 1: Read Excel file and extract relevant data ===
% Skip the first two header rows to get to the data
opts = detectImportOptions('HO-LGO.xlsm', 'Sheet', 'HO-LGO 30min');
opts.DataRange = 'A3';  % Start from row 3

% Read the data table
T = readtable('HO-LGO.xlsm', opts);

% Define column indices for relevant data:
% column_timestamp = time
% columnHO = [HO Bid, HO Ask], columnLGO = [LGO Bid, LGO Ask]
column_timestamp = 2; 
columnHO = [3, 7]; 
columnLGO = [4, 8];

% Currency converters: HO in $/gallon, LGO in $/barrel
converterHO = 42; 
converterLGO = 20/149;

% Extract midprices and log-returns from bid/ask data
[Rt, timestamp, ~, ~, bid_HO, bid_LGO, ask_HO, ask_LGO] = ...
    extractionBidAskMidLogReturn(T, column_timestamp, columnHO, columnLGO, converterHO, converterLGO, flag);

% === Step 2: Clean Data and Split into IS/OS Periods ===
InputFormat = 'yyyy-MM-dd HH:mm:ss'; 
splitTime = calmonths(9); 
verbose = true;

% Remove statistical outliers from log-returns
[Rt_filtered, time_filtered, index_filtered] = removeOutliers(Rt, timestamp, InputFormat, verbose);

% Split filtered data into In-Sample (IS) and Out-of-Sample (OS)
[Rt_IS_filtered, time_IS_filtered, Rt_OS_filtered, time_OS_filtered] = ...
    IS_OS_split(Rt_filtered, time_filtered, splitTime, verbose);

% === Step 3: In-Sample Calibration for NY Trading Hours 9:00–16:00 ===
flag = true;
verbose = true;
starting_hour = 9;
ending_hour = 16;

% Filter IS data between 9:00 and 16:00
table_IS_Filtered_9_16 = filterTimeWindow(time_IS_filtered, Rt_IS_filtered, starting_hour, ending_hour, flag, verbose);

% Estimate time increment per observation
proportion = computeTimeProportion(timestamp(1), splitTime, timestamp(end));
deltaT = proportion / height(table_IS_Filtered_9_16);

% Extract log-returns for calibration
Rt_9_16 = table2array(table_IS_Filtered_9_16(:, 2));

% Calibrate OU process parameters (η, θ, σ)
[eta_hat, k_hat, sigma_hat] = calibration(Rt_9_16, deltaT);

% === Step 4: Parameter Simulation via Bootstrapping ===
n_sim = 1e2;
rng(42);  % For reproducibility

% Simulate parameter estimates using bootstrap
[sigma_hat_vector, k_hat_vector, eta_hat_vector] = simulation(Rt_9_16, n_sim, deltaT, eta_hat, k_hat, sigma_hat);

% Compute 95% Confidence Intervals for parameters
alpha = 0.05;
ci_k     = prctile(k_hat_vector,     [alpha * 50, 100 - alpha * 50]);
ci_sigma = prctile(sigma_hat_vector, [alpha * 50, 100 - alpha * 50]);
ci_eta   = prctile(eta_hat_vector,   [alpha * 50, 100 - alpha * 50]);

% Print estimated parameters and confidence intervals
print_MLE_CI(k_hat, eta_hat, sigma_hat, alpha, ci_k, ci_sigma, ci_eta, ...
             k_hat_vector, sigma_hat_vector, eta_hat_vector, ...
             starting_hour, ending_hour);

% === Step 5: Repeat Calibration for NY Trading Hours 8:00–16:00 ===
starting_hour = 8; 
ending_hour = 16;

% Filter IS data between 8:00 and 16:00
table_IS_Filtered_8_16 = filterTimeWindow(time_IS_filtered, Rt_IS_filtered, starting_hour, ending_hour, flag, verbose);

% Recalculate deltaT for this time window
proportion = computeTimeProportion(timestamp(1), splitTime, timestamp(end));
deltaT = proportion / height(table_IS_Filtered_8_16);

% Extract log-returns and calibrate OU parameters
Rt_8_16 = table2array(table_IS_Filtered_8_16(:, 2));
[eta_hat, k_hat, sigma_hat] = calibration(Rt_8_16, deltaT);

% Simulate bootstrap distribution of OU parameters
rng(42);  % Same seed for consistency
[sigma_hat_vector, k_hat_vector, eta_hat_vector] = ...
    simulation(Rt_8_16, n_sim, deltaT, eta_hat, k_hat, sigma_hat);

% Compute and print 95% confidence intervals
ci_k     = prctile(k_hat_vector,     [alpha * 50, 100 - alpha * 50]);
ci_sigma = prctile(sigma_hat_vector, [alpha * 50, 100 - alpha * 50]);
ci_eta   = prctile(eta_hat_vector,   [alpha * 50, 100 - alpha * 50]);

print_MLE_CI(k_hat, eta_hat, sigma_hat, alpha, ci_k, ci_sigma, ci_eta, ...
             k_hat_vector, sigma_hat_vector, eta_hat_vector, ...
             starting_hour, ending_hour);

% === Step 6: Final Timing ===
elapsedTimeB = toc;
fprintf('Execution time for Question B: %.4f seconds\n', elapsedTimeB);

%% === Question C: Trading Cost and Strategy Analysis ===
% This section analyzes transaction costs and their impact on the trading strategy,
% including visualization of cost distributions and optimal trading bands.
% -------------------------------------------------------------------------
fprintf('=================================== Question C ===================================\n');
tic;  % Start performance timer

% === 1. Compute Transaction Cost Metrics ===
% Calculate round-trip transaction costs and strategy parameters:
% - C: Raw transaction costs (log ratios)
% - expected_C: Mean transaction cost
% - SIGMA: Annualized stationary volatility (σ/sqrt(2κ))
% - c_bar: Cost normalized by volatility (expected_C/SIGMA)
% - theta: Mean-reversion timescale (1/κ)
[C, expected_C, SIGMA, c_bar, theta] = computeTransactionCost(...
    bid_HO, bid_LGO, ask_HO, ask_LGO, timestamp, ...
    sigma_hat, k_hat, starting_hour, ending_hour, splitTime, index_filtered);

% === 2. Visualize Cost Distribution ===
% Create histogram bins spanning 0 to 45% of volatility (160 bins)
edges = 0:0.0028:0.45;  % 2.8 basis point bin width

figure('Position', [100 100 800 400]);  % Set figure size [width height]

% Plot probability histogram of normalized costs (C/σ)
h = histogram(C./SIGMA, edges, ...
          'Normalization', 'probability', ...  % Show relative frequencies
          'FaceColor', [0.2 0.6 0.8], ...    % Custom blue tone
          'EdgeColor', [0.1 0.3 0.4], ...     % Darker edges for definition
          'FaceAlpha', 0.8);                  % Semi-transparent fill

% === 3. Format Visualization ===
hold on;

% Add vertical line at mean normalized cost
xline(c_bar, 'r-', 'LineWidth', 2, ...
    'Label', sprintf('Mean (%.3f\\sigma)', c_bar), ...
    'LabelOrientation', 'horizontal');

% Add annotations
title('Distribution of Normalized Transaction Costs', ...
      'FontSize', 12, 'FontWeight', 'bold');
xlabel('Transaction Cost (\sigma units)', 'FontSize', 10);
ylabel('Probability', 'FontSize', 10);
grid on;

% Set axis limits to focus on relevant range
xlim([0 0.15]);  % Focus on 0-15% of σ range where most data lies

% Add textbox with key statistics
annotation('textbox', [0.7 0.7 0.2 0.15], ...
           'String', {sprintf('Mean: %.4f\\sigma', c_bar), ...
                      sprintf('Std Dev: %.4f\\sigma', std(C./SIGMA))}, ...
           'FitBoxToText', 'on', ...
           'BackgroundColor', 'white');

% === Performance Metrics ===
fprintf('Mean normalized cost: %.4fσ\n', c_bar);

% === Strategy Parameters ===
% Set stop-loss threshold at -1.96 standard deviations
% (Common choice for 95% confidence interval in normal distributions)
l = -1.96;  % Stop-loss level in volatility units (σ)

% === Transaction Cost Sensitivity Analysis ===
% Define range of normalized transaction costs to evaluate
% (From 0.1% to 75% of volatility, 100 points)
c_vals = linspace(0.001, 0.75, 100);

% Assume full position sizing (f=1 means 100% of capital per trade)
f = 1;

% Compute optimal trading bands (u*, d*) for given parameters
[u_star, d_star] = bands(c_bar, l, SIGMA, theta, f);

% === Visualize Optimal Bands vs Transaction Costs ===
% Plot relationship between costs and trading thresholds
% flag=false: Disables saving the plot to file
plot_BANDSvsCOST(c_vals, d_vals, u_vals, c_bar, d_star, u_star, false)

% === After-Hours Market Analysis ===
% Filter and analyze trading activity during 17:00-20:00 time window
% flag=false: Returns filtered data without plotting 
% verbose=true: Displays filtering statistics
[table_OS_Filtered_17_20] = filterTimeWindow(...
    time_OS_filtered, Rt_OS_filtered, ...
    17, 20, false, true);  % 17:00 to 20:00 time window

% Testing on Out-of-Sample (OS) Dataset
% === 1. Normalize the OS time series using regime-estimated parameters ===
% Subtract long-term mean (eta_hat) and divide by stationary volatility (SIGMA)
X_OS = (table2array(table_OS_Filtered_17_20(:,2)) - eta_hat) / SIGMA;

% === 2. Plot OS signal with optimal trading thresholds ===
plot_XOS(X_OS, d_star, u_star, l);

% === 3. Initialize wealth ===
w0 = 1;

% === 4. Compute max admissible transaction cost from thresholds ===
% This is useful to check whether current cost is within feasible region
[C_max, p_pls, p_mns] = maximum_transaction_cost(d_star, u_star, l);

% === 5. Set trading parameters ===
f = 1;                     % Leverage factor
scaling_factor = 4;        % Number of strategy cycles per year (quarterly strategy)
verbose = false;           % Suppress verbose output

% === 6. Simulate actual trading strategy on OS data ===
% Computes the annualized return of the strategy using historical OS path
ann_return = optimizedReturn(X_OS, d_star, u_star, l, c_bar, SIGMA, f, scaling_factor, w0, verbose);

% === 7. Compute expected theoretical return using the OU model ===
% μ* as derived from the OU-based expected value formula
mu_theoritical = evaluate_mu(d_star, u_star, c_bar, theta, l, SIGMA, f);

% === 8. Print diagnostic metrics ===
% Display hitting probabilities and return estimates for evaluation
fprintf('Probabilities and sum [%.6f, %.6f, %.6f]\n', p_pls, p_mns, p_pls + p_mns);
fprintf('Expected theoretical result over 1 year: %.6f\n', mu_theoritical);
fprintf('Actual transaction cost (normalized): %.6f\n', c_bar);
fprintf('Actual result over 12 months: %.6f\n', ann_return);

elapsedTimeC = toc;
fprintf('Execution time for Question C: %.4f seconds\n', elapsedTimeC);

%% Question D
fprintf('=================================== Question D ===================================\n');
tic;
% === 1. Compute Optimal Leverage ===
% This finds the theoretical leverage that maximizes expected return
opt_lev = optimalLeverage(SIGMA, theta, c_bar, l, 100);  % Grid of 100 points

% === 2. Define Leverage Levels for Evaluation ===
% Try different leverage levels including the optimal one
leverage_levels = [1, 5, 20, 28, opt_lev];  % Test a wide range including edge and optimal

% === 3. Compute Optimal Trading Bands for Each Leverage ===
% Returns upper and lower thresholds for each leverage value
[u_star_vec, d_star_vec] = bands(c_bar, l, SIGMA, theta, leverage_levels);

% === 4. Compute Theoretical Returns ===
% Evaluate μ(f) using analytical expression for OU-based model
% Multiply by 100 to express in annual percentage terms
mu_vector = evaluate_mu(d_star_vec, u_star_vec, c_bar, theta, l, SIGMA, leverage_levels) * 100;

% === 5. Compute Empirical (Simulated) Returns on OS Data ===
% Simulates each strategy using the OS time series
empirical_returns = optimizedReturn(X_OS, d_star_vec, u_star_vec, l, ...
                                    c_bar, SIGMA, leverage_levels, ...
                                    scaling_factor, w0, verbose);

% === 6. Plot Theoretical vs. Empirical Returns vs. Leverage ===
plot_leveragesVSreturns(leverage_levels, empirical_returns, opt_lev, mu_vector);


% === Confidence Interval Computation for Trading Parameters ===% Set confidence level and upper bound for cost grid
alpha = 0.05;               % Significance level for 95% confidence interval
CostUpperBound = 0.75;      % Upper limit for transaction cost search space

% Compute 95% confidence intervals for d*, u*, and μ* 
% using bootstrapped estimates of sigma and kappa
[ci_d, ci_u, ci_mu] = confidenceIntervalAdv(sigma_hat_vector, k_hat_vector, ...
                                            l, expected_C, opt_lev, ...
                                            alpha, CostUpperBound);

% Display the 95% confidence intervals for each parameter
fprintf('=== Confidence intervals for d, u, and mu ===\n');
fprintf('95%% CI for d  : [%.15f, %.15f]\n', ci_d(1), ci_d(2));
fprintf('95%% CI for u  : [%.15f, %.15f]\n', ci_u(1), ci_u(2));
fprintf('95%% CI for mu : [%.15f, %.15f]\n', ci_mu(1), ci_mu(2));

elapsedTimeD = toc;
fprintf('Execution time for Question D: %.4f seconds\n', elapsedTimeD);

%% === E. Impact of Stop-Loss Level (l) on Annualized Return ===
fprintf('=================================== Question E ===================================\n');
tic;
% This section evaluates how changing the stop-loss level `l` affects
% the annualized return of the trading strategy.

% Define a vector of stop-loss thresholds (standard normal quantiles)
l_vector = [-1.282, -1.645, -1.96, -2.326];  % Corresponding to 90%, 95%, 97.5%, 99% confidence levels
length_l_vector = length(l_vector);

% Use fixed leverage
f = 1;

% Preallocate vector to store annualized percentage returns
ann_pct_return_vector = zeros(length_l_vector, 1);

% Loop through each stop-loss level and compute return
for i = 1:length_l_vector
    l = l_vector(i);  % Current stop-loss
    
    % Compute optimal bands for this stop-loss
    [u_star, d_star, ~] = bands(c_bar, l, SIGMA, theta, f);
    
    % Simulate and store the annualized return from the strategy
    ann_pct_return_vector(i) = optimizedReturn(X_OS, d_star, u_star, ...
                                               l, c_bar, SIGMA, ...
                                               f, scaling_factor, ...
                                               w0, verbose);
end

% === Customized Plot 1: Return vs. Stop-Loss Level ===
figure;
plot(l_vector, ann_pct_return_vector, '-o', ...
     'LineWidth', 2, ...
     'MarkerSize', 8, ...
     'MarkerFaceColor', 'b', ...
     'Color', [0.2 0.4 0.8]);

grid on;
grid minor;

xlabel('Stop-loss threshold (l)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Annualized return (%)', 'FontSize', 12, 'FontWeight', 'bold');
title('Effect of Stop-Loss Level on Annualized Return', 'FontSize', 14);

% Annotate data points with l values
for i = 1:length(l_vector)
    text(l_vector(i), ann_pct_return_vector(i) + 0.01, ...
         sprintf('l = %.3f', l_vector(i)), ...
         'FontSize', 10, 'HorizontalAlignment', 'center');
end

xlim([min(l_vector)-0.1, max(l_vector)+0.1]);
ylim([min(ann_pct_return_vector)-0.02, max(ann_pct_return_vector)+0.02]);

set(gca, 'FontSize', 11, 'LineWidth', 1.2);

% === Customized Plot 2: OU Process with Stop-Loss Thresholds ===
figure;
plot(X_OS, 'Color', [0.1 0.1 0.1], 'LineWidth', 1.5); hold on;

% Add each stop-loss threshold with a unique color and label
colors = lines(length(l_vector));
for i = 1:length(l_vector)
    yline(l_vector(i), '--', ...
          'Color', colors(i,:), ...
          'LineWidth', 1.5, ...
          'Label', sprintf('l = %.3f', l_vector(i)), ...
          'LabelHorizontalAlignment', 'left', ...
          'LabelVerticalAlignment', 'middle', ...
          'FontSize', 10);
end

xlabel('Time', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Normalized log-price process', 'FontSize', 12, 'FontWeight', 'bold');
title('Stop-Loss Thresholds on Normalized OU Process', 'FontSize', 14);
grid on; grid minor;

legend(['OU Process', arrayfun(@(x) sprintf('l = %.3f', x), l_vector, 'UniformOutput', false)], ...
       'Location', 'best');

set(gca, 'FontSize', 11, 'LineWidth', 1.2);

% --- Initialize input vectors and parameters ---
% f_vector: Vector of leverage/frequency factors (e.g., 1x, 2x, 5x, and an optimized value)
f_vector = [1, 2, 5, opt_lev]; 

% l_vector: Vector of critical values (standard normal quantiles for confidence levels):
%   -1.282 ≈ 10% (left tail), -1.645 ≈ 5%, -1.96 ≈ 2.5%, -2.326 ≈ 1%
l_vector = [-1.282, -1.645, -1.96, -2.326];

% scaling_factor: Scales the output (e.g., for annualization)
scaling_factor = 4; 

% w0: Initial weight/wealth (default = 1 for percentage calculations)
w0 = 1; 

% verbose_optimizedReturned: Flag to enable/disable verbose output during optimization
verbose_optimizedReturned = false;

% --- Initialize results matrix ---
% Preallocate a matrix to store results: 
%   - Rows: 16 (4 f_values × 4 l_values)
%   - Columns: 7 (see block structure below)
matrix = zeros(length(f_vector) * length(l_vector), 7); 

% --- Populate matrix by iterating over f_vector and l_vector ---
row = 1;  % Start at row 1 for filling the results matrix

for k = 1:length(f_vector)
    % Current leverage/frequency value from f_vector
    f = f_vector(k);
    
    % --- Compute key outputs for all l_values at once ---
    % Calls a function `matrixCreation` that returns vectors of length 4 (one per l_value):
    %   ann_return_vector: Annualized returns
    %   u_star: Optimal thresholds (e.g., for trading)
    %   d_star: Optimal stop-loss levels
    %   mu_lev_stop_loss: Expected return with leverage and stop-loss
    %   trade_time: Time between trades (scaled by theta later)
    [ann_return_vector, u_star, d_star, mu_lev_stop_loss, trade_time] = ...
        matrixCreation(X_OS, c_bar, SIGMA, theta, l_vector, f, scaling_factor, w0, verbose_optimizedReturned);
    
    % --- Construct a 4x7 block for the current f value ---
    % Columns:
    %   1. l_value (critical value)
    %   2. f (current leverage/frequency)
    %   3. d_star (optimal stop-loss)
    %   4. u_star (optimal threshold)
    %   5. trade_time * theta (scaled trading time)
    %   6. mu_lev_stop_loss (expected return)
    %   7. ann_return_vector (annualized return)
    block = [l_vector(:), ...           % Column 1: l_values (as column vector)
             f * ones(4,1), ...          % Column 2: Replicate f for all 4 rows
             d_star(:), ...             % Column 3: Stop-loss levels
             u_star(:), ...              % Column 4: Thresholds
             trade_time(:)*theta, ...    % Column 5: Scaled trading time
             mu_lev_stop_loss(:), ...    % Column 6: Expected returns
             ann_return_vector(:)];      % Column 7: Annualized returns
    
    % --- Insert block into the results matrix ---
    % Assign the 4x7 block to the next available rows (e.g., rows 1:4, 5:8, etc.)
    matrix(row:row+3, :) = block;
    
    % Move the row pointer forward by 4 for the next block
    row = row + 4;
end

elapsedTimeE = toc;
fprintf('Execution time for Question E: %.4f seconds\n', elapsedTimeE);
fprintf('Total execution time for the all code: %.4f seconds\t%.4f minutes\t%.4f hours\n\n', elapsedTimeA + elapsedTimeB + elapsedTimeC + elapsedTimeD + elapsedTimeE, (elapsedTimeA + elapsedTimeB + elapsedTimeC + elapsedTimeD + elapsedTimeE)/60, (elapsedTimeA + elapsedTimeB + elapsedTimeC + elapsedTimeD + elapsedTimeE)/3600);