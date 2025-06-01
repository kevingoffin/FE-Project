%% Analysis with the GovernativeFutures dataset
clear; 
clc;
close all
format long

%% Question G: Futures Pairs Trading Strategy Analysis
% This section analyzes two government futures pairs (IKA/RXA and OATA/OEA) 
% through: calibration, simulation, optimal band calculation, and performance testing
% -------------------------------------------------------------------------
fprintf('=================================== Question G ===================================\n');
tic;  % Start execution timer

% 1. Data Import and Preparation
% Read Excel file containing futures data (skip header row)
opts = detectImportOptions('GovernativeFutures.xlsx', 'Sheet', 'sheet1');
opts.DataRange = 'A2'; % Start from row 2 to skip headers
T = readtable('GovernativeFutures.xlsx', opts);

fprintf('*********************************** IXA/RXA ***********************************\n');
% Extract IKA/RXA pair data
column_timestamp = 1; columnIKA = 2; columnRXA = 5; 
converterIKA = 1; converterRXA = 1; flag = false;
[Rt_IKA_RXA, timestamp, mid_IKA, mid_RXA, ~, ~, ~, ~] = ...
    extractionBidAskMidLogReturn(T, column_timestamp, columnIKA, columnRXA, converterIKA, converterRXA, flag);

% 2. Data Cleaning and Splitting
InputFormat = 'yyyy-MM-dd HH:mm:ss'; 
splitTime = calmonths(4); % Split into 4-month periods
verbose = true;

% Process IKA/RXA pair
[Rt_IKA_RXA_filtered, time_IKA_RXA, index_IKA_RXA_filtered] = ...
    removeOutliers(Rt_IKA_RXA, timestamp, InputFormat, verbose);
[Rt_IKA_RXA_IS, time_IKA_RXA_IS, Rt_IKA_RXA_OS, time_IKA_RXA_OS] = ...
    IS_OS_split(Rt_IKA_RXA_filtered, time_IKA_RXA, splitTime, verbose);

% 3. Intraday Filtering (8:00-16:00)
flag = true; verbose = true; 
starting_hour = 8; ending_hour = 16; % Trading hours
[table_IS_IKA_RXA_8_16] = filterTimeWindow(time_IKA_RXA_IS, Rt_IKA_RXA_IS, starting_hour, ending_hour, flag, verbose);

% 4. Model Calibration
% Calculate time proportion for proper scaling
proportion = computeTimeProportion(timestamp(1), splitTime, timestamp(end));
deltaT_IKA_RXA = proportion/height(table_IS_IKA_RXA_8_16); 
Rt_IKA_RXA = table2array(table_IS_IKA_RXA_8_16(:, 2));
[eta_hat_IKA_RXA, k_hat_IKA_RXA, sigma_hat_IKA_RXA] = calibration(Rt_IKA_RXA, deltaT_IKA_RXA);

% 5. Monte Carlo Simulation
n_sim = 1e2; % Number of simulations
rng(42); % Set random seed for reproducibility
[sigma_hat_IKA_RXA_sim, k_hat_IKA_RXA_sim, eta_hat_IKA_RXA_sim] = simulation(Rt_IKA_RXA, n_sim, deltaT_IKA_RXA, eta_hat_IKA_RXA, k_hat_IKA_RXA, sigma_hat_IKA_RXA);

% 6. Confidence Intervals (95%)
alpha = 0.05;
start_hour = 8; end_hour = 16;
ci_k_IKA_RXA = prctile(k_hat_IKA_RXA_sim, [alpha * 50, 100 - alpha * 50]);
ci_sigma_IKA_RXA = prctile(sigma_hat_IKA_RXA_sim, [alpha * 50, 100 - alpha * 50]);
ci_eta_IKA_RXA = prctile(eta_hat_IKA_RXA_sim, [alpha * 50, 100 - alpha * 50]);

% Print results
fprintf('===Parameters for IKA/RXA===\n');
print_MLE_CI(k_hat_IKA_RXA, eta_hat_IKA_RXA, sigma_hat_IKA_RXA, alpha, ...
             ci_k_IKA_RXA, ci_sigma_IKA_RXA, ci_eta_IKA_RXA, ...
             k_hat_IKA_RXA_sim, sigma_hat_IKA_RXA_sim, eta_hat_IKA_RXA_sim, ...
             start_hour, end_hour);

% 7. Optimal Trading Strategy
l = -1.960; % 2.5% quantile stop-loss
f = 1; % No leverage
c_vals = linspace(0.001, 1.00, 100); % Cost range
bidAskSpread = 0.01; % 1% spread
[d_vals_RXA_IKA, u_vals_RXA_IKA, d_star_RXA_IKA, u_star_RXA_IKA, ...
 c_bar_RXA_IKA, SIGMA_RXA_IKA, theta_RXA_IKA, expected_C_RXA_IKA] = ...
    optimizedTradingStrategy(mid_RXA, mid_IKA, sigma_hat_IKA_RXA, k_hat_IKA_RXA, ...
                            l, f, c_vals, bidAskSpread);

% 8. Strategy Visualization
% IKA/RXA Band Plot
figure('Position', [100 100 800 400]);
plot(c_vals, -d_vals_RXA_IKA, 'r-', 'LineWidth', 1.5); 
hold on;
plot(c_vals, u_vals_RXA_IKA, 'b--', 'LineWidth', 1.5);
xline(c_bar_RXA_IKA, 'g--', 'LineWidth', 1.5, 'Label', 'c_{bar}');
plot([c_bar_RXA_IKA, c_bar_RXA_IKA], [-d_star_RXA_IKA, u_star_RXA_IKA], ...
     'o', 'MarkerEdgeColor','c','MarkerFaceColor','c','MarkerSize',8);
xlabel('Transaction Cost (c) in \sigma units');
ylabel('Optimal Trading Bands');
legend('|d^*| (Entry)', 'u^* (Exit)', 'Location', 'NorthWest');
title('IKA/RXA: Optimal Trading Bands vs Transaction Cost');
grid on;
set(gca, 'FontSize', 10);

% 9. Out-of-Sample Testing (17:00-20:00)
flag = false; verbose = true; 
starting_hour = 17; ending_hour = 20; % After-hours period
[table_IKA_RXA_OS] = filterTimeWindow(time_IKA_RXA_OS, Rt_IKA_RXA_OS, starting_hour, ending_hour, flag, verbose);

% Prepare returns calculation
scaling_factor = 6; w0 = 1; verbose = true; verbose_optimizedReturned = false;
Rt_IKA_RXA_OS_17_20 = table2array(table_IKA_RXA_OS(:,2));
[X_OS_IKA_RXA, value_IKA_RXA, ~] = long_run_futures(Rt_IKA_RXA_OS_17_20, ...
    eta_hat_IKA_RXA, theta_RXA_IKA, SIGMA_RXA_IKA, u_star_RXA_IKA, d_star_RXA_IKA, ...
    l, c_bar_RXA_IKA, f, w0, scaling_factor, verbose, verbose_optimizedReturned);

% 10. Leverage Analysis
f_max = 20; % Maximum leverage to test
f = [1, 5, 10, 28, 35, 50, 65, 75, 90, 120, 0]; % Specific leverage levels
scaling_factor = 6; w0 = 1; 
verbose_optimizeReturn = false; alpha = 0.01;
[opt_lev_IKA_RXA, rtn_IKA_RXA, mu_vector_IKA_RXA] = ...
    run_leverage(X_OS_IKA_RXA, SIGMA_RXA_IKA, theta_RXA_IKA, c_bar_RXA_IKA, l, ...
                f_max, sigma_hat_IKA_RXA_sim, k_hat_IKA_RXA_sim, expected_C_RXA_IKA, ...
                d_star_RXA_IKA, u_star_RXA_IKA, value_IKA_RXA, f, w0, scaling_factor, ...
                verbose_optimizeReturn, alpha);

% 11. Stop-Loss Sensitivity Analysis
l_vector = [-1.282, -1.645, -1.96, -2.326]; % Various stop-loss levels (10% to 1% tails)
f = 1; scaling_factor = 6; w0 = 1; 
verbose_optimizedReturned = false;
[ann_return_IKA_RXA] = run_stop_loss(X_OS_IKA_RXA, c_bar_RXA_IKA, SIGMA_RXA_IKA, ...
                                    theta_RXA_IKA, l_vector, f, scaling_factor, w0, ...
                                    verbose_optimizedReturned);

fprintf('*********************************** OATA/OEA ***********************************\n');

% Extract OATA/OEA pair data  
columnOATA = 3; columnOEA = 4; 
converterOATA = 1; converterOEA = 1;
[Rt_OATA_OEA, ~, mid_OATA, mid_OEA, ~, ~, ~, ~] = ...
    extractionBidAskMidLogReturn(T, column_timestamp, columnOATA, columnOEA, converterOATA, converterOEA, flag);

% 2. Data Cleaning and Splitting
InputFormat = 'yyyy-MM-dd HH:mm:ss'; 
splitTime = calmonths(4); % Split into 4-month periods
verbose = true;

% Process OATA/OEA pair  
[Rt_OATA_OEA_filtered, time_OATA_OEA, index_OATA_OEA] = ...
    removeOutliers(Rt_OATA_OEA, timestamp, InputFormat, verbose);
[Rt_OATA_OEA_IS, time_OATA_OEA_IS, Rt_OATA_OEA_OS, time_OATA_OEA_OS] = ...
    IS_OS_split(Rt_OATA_OEA_filtered, time_OATA_OEA, splitTime, verbose);

% 3. Intraday Filtering (8:00-16:00)
flag = true; verbose = true; 
starting_hour = 8; ending_hour = 16; % Trading hours
[table_IS_OATA_OEA_8_16] = filterTimeWindow(time_OATA_OEA_IS, Rt_OATA_OEA_IS, starting_hour, ending_hour, flag, verbose);

% 4. Model Calibration
% Calculate time proportion for proper scaling
proportion = computeTimeProportion(timestamp(1), splitTime, timestamp(end));
deltaT_OATA_OEA = proportion/height(table_IS_OATA_OEA_8_16); 
Rt_OATA_OEA = table2array(table_IS_OATA_OEA_8_16(:, 2));
[eta_hat_OATA_OEA, k_hat_OATA_OEA, sigma_hat_OATA_OEA] = calibration(Rt_OATA_OEA, deltaT_OATA_OEA);

% 5. Monte Carlo Simulation
n_sim = 1e2; % Number of simulations
rng(42); % Set random seed for reproducibility
[sigma_hat_OATA_OEA_sim, k_hat_OATA_OEA_sim, eta_hat_OATA_OEA_sim] = ...
    simulation(Rt_OATA_OEA, n_sim, deltaT_OATA_OEA, eta_hat_OATA_OEA, k_hat_OATA_OEA, sigma_hat_OATA_OEA);

% 6. Confidence Intervals (95%)
alpha = 0.05;
start_hour = 8; end_hour = 16;

% Calculate CIs for OATA/OEA
ci_k_OATA_OEA = prctile(k_hat_OATA_OEA_sim, [alpha * 50, 100 - alpha * 50]);
ci_sigma_OATA_OEA = prctile(sigma_hat_OATA_OEA_sim, [alpha * 50, 100 - alpha * 50]);
ci_eta_OATA_OEA = prctile(eta_hat_OATA_OEA_sim, [alpha * 50, 100 - alpha * 50]);

% Print results
fprintf('===Parameters for OATA/OEA===\n');
print_MLE_CI(k_hat_OATA_OEA, eta_hat_OATA_OEA, sigma_hat_OATA_OEA, alpha, ...
             ci_k_OATA_OEA, ci_sigma_OATA_OEA, ci_eta_OATA_OEA, ...
             k_hat_OATA_OEA_sim, sigma_hat_OATA_OEA_sim, eta_hat_OATA_OEA_sim, ...
             start_hour, end_hour);

% 7. Optimal Trading Strategy
l = -1.960; % 2.5% quantile stop-loss
f = 1; % No leverage
c_vals = linspace(0.001, 1.00, 100); % Cost range
bidAskSpread = 0.01; % 1% spread

% Optimize OATA/OEA strategy
[d_vals_OATA_OEA, u_vals_OATA_OEA, d_star_OATA_OEA, u_star_OATA_OEA, ...
 c_bar_OATA_OEA, SIGMA_OATA_OEA, theta_OATA_OEA, expected_C_OATA_OEA] = ...
    optimizedTradingStrategy(mid_OATA, mid_OEA, sigma_hat_OATA_OEA, k_hat_OATA_OEA, ...
                            l, f, c_vals, bidAskSpread);

% 8. Strategy Visualization
% OATA/OEA Band Plot
figure('Position', [100 100 800 400]);
plot(c_vals, -d_vals_OATA_OEA, 'r-', 'LineWidth', 1.5); 
hold on;
plot(c_vals, u_vals_OATA_OEA, 'b--', 'LineWidth', 1.5);
xline(c_bar_OATA_OEA, 'g--', 'LineWidth', 1.5, 'Label', 'c_{bar}');
plot([c_bar_OATA_OEA, c_bar_OATA_OEA], [-d_star_OATA_OEA, u_star_OATA_OEA], ...
     'o', 'MarkerEdgeColor','c','MarkerFaceColor','c','MarkerSize',8);
xlabel('Transaction Cost (c) in \sigma units');
ylabel('Optimal Trading Bands');
legend('|d^*| (Entry)', 'u^* (Exit)', 'Location', 'NorthWest');
title('OATA/OEA: Optimal Trading Bands vs Transaction Cost');
grid on;
set(gca, 'FontSize', 10);

% 9. Out-of-Sample Testing (17:00-20:00)
flag = false; verbose = true; 
starting_hour = 17; ending_hour = 20; % After-hours period
[table_OATA_OEA_OS] = filterTimeWindow(time_OATA_OEA_OS, Rt_OATA_OEA_OS, starting_hour, ending_hour, flag, verbose);

% Prepare returns calculation
scaling_factor = 6; w0 = 1; verbose = true; verbose_optimizedReturned = false;

% Calculate OS performance
Rt_OATA_OEA_OS_17_20 = table2array(table_OATA_OEA_OS(:,2));
[X_OS_OATA_OEA, value_OATA_OEA, ~] = long_run_futures(Rt_OATA_OEA_OS_17_20, ...
    eta_hat_OATA_OEA, theta_OATA_OEA, SIGMA_OATA_OEA, u_star_OATA_OEA, d_star_OATA_OEA, ...
    l, c_bar_OATA_OEA, f, w0, scaling_factor, verbose, verbose_optimizedReturned);

% 10. Leverage Analysis
f_max = 20; % Maximum leverage to test
f = [1, 5, 10, 28, 35, 50, 65, 75, 90, 120, 0]; % Specific leverage levels
scaling_factor = 6; w0 = 1; 
verbose_optimizeReturn = false; alpha = 0.01;    
[opt_lev_OATA_OEA, rtn_OATA_OEA, mu_vector_OATA_OEA] = ...
    run_leverage(X_OS_OATA_OEA, SIGMA_OATA_OEA, theta_OATA_OEA, c_bar_OATA_OEA, l, ...
                f_max, sigma_hat_OATA_OEA_sim, k_hat_OATA_OEA_sim, expected_C_OATA_OEA, ...
                d_star_OATA_OEA, u_star_OATA_OEA, value_OATA_OEA, f, scaling_factor, w0, ...
                verbose_optimizeReturn, alpha);

% 11. Stop-Loss Sensitivity Analysis
l_vector = [-1.282, -1.645, -1.96, -2.326]; % Various stop-loss levels (10% to 1% tails)
f = 1; scaling_factor = 6; w0 = 1; 
verbose_optimizedReturned = false;                             
[ann_return_OATA_OEA] = run_stop_loss(X_OS_OATA_OEA, c_bar_OATA_OEA, SIGMA_OATA_OEA, ...
                                     theta_OATA_OEA, l_vector, f, scaling_factor, w0, ...
                                     verbose_optimizedReturned);

% Final Output
elapsedTimeG = toc;
fprintf('\n=== Execution Summary ===\n');
fprintf('Total execution time question G: %.4f seconds\n', elapsedTimeG);
fprintf('IKA/RXA optimal leverage: %.1fx\n', opt_lev_IKA_RXA);
fprintf('OATA/OEA optimal leverage: %.1fx\n', opt_lev_OATA_OEA);
fprintf('IKA/RXA best stop-loss: %.3fσ\n', l_vector(ann_return_IKA_RXA == max(ann_return_IKA_RXA)));
fprintf('OATA/OEA best stop-loss: %.3fσ\n', l_vector(ann_return_OATA_OEA == max(ann_return_OATA_OEA)));