clear; clc;
close all
format long
%% Question 1B
tic
% === Parametri OU ===
theta = 0.041;
sigma = 0.0147;   % std dev stazionaria

% === Stop-loss (in S unit) ===
l = -1.960;

% === Transaction cost (in S unit) ===
c_vals = linspace(0.001, 0.75, 100);

% === Leverage ===
f = 1;
[d_vals, u_vals] = maximize_mu(c_vals, l, sigma, theta, f);

% === Plot risultati ===
plot_BANDSvsCOST(c_vals, d_vals, u_vals,[],[],[],1);
toc
%% Question 2 

% Leggi il file Excel (salta le prime due righe di intestazione)
opts = detectImportOptions('HO-LGO.xlsm', 'Sheet', 'HO-LGO 30min');
opts.DataRange = 'A3'; % Inizia dalla riga 3
T = readtable('HO-LGO.xlsm', opts);

% Estrai le colonne di interesse
% Timestamp, Bid HO, Ask HO, Bid LGO, Ask LGO
[Rt, timestamp, bid_HO, bid_LGO, ask_HO, ask_LGO]= dataset_preparation(T);
[Rt_IS_filtered, Rt_OS_filtered, time_IS_filtered, time_OS_filtered] = cleaner(Rt, timestamp, 9);

%% Converting data to NY time 9:00-16:00

% % Specifica esplicitamente che i timestamp sono in UTC
time_IS_NY = time_IS_filtered;
time_OS_NY = time_OS_filtered;
flag = 1;
[Rt_IS_NY_Filtered, Rt_OS_NY_Filtered] = filter_NY(time_IS_NY, time_OS_NY, Rt_IS_filtered, Rt_OS_filtered, 9, 16, flag);

% Calibration
deltaT = 0.75/height(Rt_IS_NY_Filtered);
[eta_hat, k_hat, sigma_hat] = calibration(Rt_IS_NY_Filtered, deltaT, 1);

% Process simulation
Rt_0 = table2array(Rt_IS_NY_Filtered(:, 2));
n_sim = 1e4;
rng(42);
[sigma_hat_i, k_hat_i, eta_hat_i] = simulation(Rt_0, n_sim, deltaT, eta_hat, k_hat, sigma_hat);

% Confidence Intervals 95%
ci_k     = prctile(k_hat_i,     [2.5, 97.5]);
ci_sigma = prctile(sigma_hat_i, [2.5, 97.5]);
ci_eta   = prctile(eta_hat_i,   [2.5, 97.5]);
alpha=0.05;
print_MLE_CI(k_hat, eta_hat, sigma_hat, alpha, ci_k, ci_sigma, ci_eta,k_hat_i, sigma_hat_i, eta_hat_i, 9 );

%% Repeting with 8:00-16:00 NYT
flag = 1;
[Rt_IS_NY_Filtered, Rt_OS_NY_Filtered] = filter_NY(time_IS_NY, time_OS_NY, Rt_IS_filtered, Rt_OS_filtered, 8, 16, flag);

% Calibration
deltaT = 0.75/height(Rt_IS_NY_Filtered);
[eta_hat, k_hat, sigma_hat] = calibration(Rt_IS_NY_Filtered, deltaT, 1);

% Process simulation
Rt_0 = table2array(Rt_IS_NY_Filtered(:, 2));
n_sim = 100;
rng(42);
[sigma_hat_i, k_hat_i, eta_hat_i] = simulation(Rt_0, n_sim, deltaT, eta_hat, k_hat, sigma_hat);

% Confidence Intervals 95%
ci_k     = prctile(k_hat_i,     [2.5, 97.5]);
ci_sigma = prctile(sigma_hat_i, [2.5, 97.5]);
ci_eta   = prctile(eta_hat_i,   [2.5, 97.5]);

print_MLE_CI(k_hat, eta_hat, sigma_hat, alpha, ci_k, ci_sigma, ci_eta,k_hat_i, sigma_hat_i, eta_hat_i, 8)
%% Question C
flag = 1;
[C, expected_C, SIGMA, c_bar, theta]=computeC(bid_HO, bid_LGO, ask_HO, ask_LGO, flag, timestamp, time_IS_NY,time_OS_NY, sigma_hat, k_hat);
plot_c_histogram(C, SIGMA);

% === Stop-loss fisso (in unità di S) ===
l = -1.96;

% === Costi di transazione (in unità di S) ===
c_vals = linspace(0.001, 0.75, 100);
f=1;
[u_star, d_star] = bands(c_bar, l, SIGMA, theta, f);

% === Plot risultati ===
flag = 2;
plot_BANDSvsCOST(c_vals, d_vals, u_vals, c_bar, d_star, u_star, flag)
[Rt_IS_NY_Filtered, Rt_OS_NY_Filtered] = filter_NY(time_IS_NY, time_OS_NY, Rt_IS_filtered, Rt_OS_filtered, 17, 20, flag);

%% testing on OS dataset
 % normalization at regime
X_OS = (table2array(Rt_OS_NY_Filtered(:,2)) - eta_hat)/SIGMA; 
plot_XOS(X_OS, d_star, u_star, l);
[C_max, p_pls, p_mns]=maximum_transaction_cost(d_star, u_star, l);
f = 1;
[ann_return] = billionaire(X_OS, d_star, u_star, l, c_bar, SIGMA, f, 4);
value = evaluate_mu(d_star, u_star, c_bar, theta, l, SIGMA, f);

fprintf('probabilities and sum [%.6f, %.6f, %.6f]\n', p_pls,  p_mns, p_pls + p_mns)
fprintf('Expected theorical result over 1 year %.6f \n', value)
fprintf('actual transaction cost normalized %.6f\n', c_bar)
fprintf('Actual result over 12 month %.6f\n', ann_return)
%fprintf('Actual result over 12 month with maximum transaction costs %.6f\n', ann_return_cmax)
%% D
%let's try with some leverage

[opt_lev] = optimalLeverage(SIGMA, theta, c_bar, l, 100);
f = [1,5,20, 28, opt_lev];
mu_vector = zeros(length(f),1);
rtn = zeros(length(f),1);
u_star_vec=zeros(length(f),1);
d_star_vec=zeros(length(f),1);
for j=1:length(f)
    [u_star_lev, d_star_lev] = bands(c_bar, l, SIGMA, theta, f(j));
    u_star_vec(j)=u_star_lev; d_star_vec(j)=d_star_lev;
    mu_vector(j) = evaluate_mu(d_star_vec(j), u_star_vec(j), c_bar, theta, l, SIGMA, f(j))*100;
    rtn(j) = billionaire(X_OS, d_star_vec(j), u_star_vec(j), l, c_bar, SIGMA, f(j), 4);
    %fprintf('Expected theorical result over 1 year %.6f %% \n', mu(d_star, u_star, c_bar)*100)
end

rtn
plot_leveragesVSreturns(f, rtn, opt_lev, mu_vector);

%%
tic
[ci_d, ci_u, ci_mu] = confidenceIntervalAdv(sigma_hat_i, k_hat_i, l, expected_C, opt_lev);

fprintf('d, u, mu: [%.15f, %.15f, %.15f]\n', d_star, u_star, value);
fprintf('===Confidence intervals for d,u,mu===\n')
fprintf('95%% CI per d :     [%.15f, %.15f]\n', ci_d(1),     ci_d(2));
fprintf('95%% CI per u: [%.15f, %.15f]\n', ci_u(1), ci_u(2));
fprintf('95%% CI per mu:   [%.15f, %.15f]\n', ci_mu(1),   ci_mu(2));
toc

%% E

l_vector = [-1.282, -1.645, -1.96, -2.326];
f = 1;
ann_pct_return_vector = zeros(length(l_vector), 1);
for i=1:length(l_vector)
    [u_star, d_star, ~] = bands(c_bar, l_vector(i), SIGMA, theta, f);
    ann_pct_return_vector(i) = billionaire(X_OS, d_star, u_star, l_vector(i), c_bar, SIGMA, f, 4);
end
figure;
plot(l_vector, ann_pct_return_vector)
grid on;
figure;
plot(X_OS, 'black'); hold on;
yline(-1.282, "red", 'LineWidth', 1.5)
yline( -1.645, "red", 'LineWidth', 1.5)
yline(-1.96, "red", 'LineWidth', 1.5)
yline(-2.326, "red", 'LineWidth', 1.5)

xlabel('time');
ylabel('log-price process');
legend('OU process', 'd*','u*','stop losses');
title('title');

%% Analysis with the new dataset
clear; clc;
close all
format long

%% Point G
opts_new = detectImportOptions('GovernativeFutures.xlsx', 'Sheet', 'sheet1');
opts_new.DataRange = 'A1'; % Inizia dalla riga 1
T_new = readtable('GovernativeFutures.xlsx', opts_new);

[timestamp_new, mid_IKA, mid_OATA, mid_OEA, mid_RXA, Rt_pair_1, Rt_pair_2]=dataset_preparation_new(T_new)

[Rt_pair_1_IS_cleaned, Rt_pair_1_OS, time_new_IS_cleaned, time_new_OS] = cleaner(Rt_pair_1, timestamp_new, 4);
[Rt_pair_2_IS_cleaned, Rt_pair_2_OS, time_new_IS_cleaned, time_new_OS] = cleaner(Rt_pair_2, timestamp_new, 4);

flag = 1;
[Rt_pair_1_IS_filtered, Rt_OS_1_Filtered] = filter_NY(time_new_IS_cleaned, time_new_OS, Rt_pair_1_IS_cleaned, Rt_pair_1_OS, 8, 16, flag);
[Rt_pair_2_IS_filtered, Rt_OS_2_Filtered] = filter_NY(time_new_IS_cleaned, time_new_OS, Rt_pair_2_IS_cleaned, Rt_pair_2_OS, 8, 16, flag);


deltaT_new = (2/3)/height(Rt_pair_2_IS_filtered);
[eta_hat_pair_1, k_hat_pair_1, sigma_hat_pair_1] = calibration(Rt_pair_1_IS_filtered, deltaT_new, 1);
[eta_hat_pair_2, k_hat_pair_2, sigma_hat_pair_2] = calibration(Rt_pair_2_IS_filtered, deltaT_new, 1);

n_sim = 100;
rng(42);
Rt_0_pair_1 = table2array(Rt_pair_1_IS_filtered(:, 2));
Rt_0_pair_2 = table2array(Rt_pair_2_IS_filtered(:, 2));

[sigma_hat_i_pair_1, k_hat_i_pair_1, eta_hat_i_pair_1] = simulation(Rt_0_pair_1, n_sim, deltaT_new, eta_hat_pair_1, k_hat_pair_1, sigma_hat_pair_1);
[sigma_hat_i_pair_2, k_hat_i_pair_2, eta_hat_i_pair_2] = simulation(Rt_0_pair_2, n_sim, deltaT_new, eta_hat_pair_2, k_hat_pair_2, sigma_hat_pair_2);

alpha=0.05;
% Mi sa che stiamo stampando due volte la stessa cosa
% figure; histogram(k_hat_i_pair_1,100,'Normalization','pdf'); title('k\_hat 1'); 
% figure; histogram(sigma_hat_i_pair_1,100,'Normalization','pdf'); title('\sigma\_hat 1');
% figure; histogram(eta_hat_i_pair_1,100,'Normalization','pdf');  title('\eta\_hat 1');
% 
% figure; histogram(k_hat_i_pair_2,100,'Normalization','pdf'); title('k\_hat 2');
% figure; histogram(sigma_hat_i_pair_2,100,'Normalization','pdf'); title('\sigma\_hat 2');
% figure; histogram(eta_hat_i_pair_2,100,'Normalization','pdf');  title('\eta\_hat 2');
% 

% Confidence Intervals 95%
ci_k_pair_1     = prctile(k_hat_i_pair_1,    [2.5, 97.5]);
ci_sigma_pair_1 = prctile(sigma_hat_i_pair_1, [2.5, 97.5]);
ci_eta_pair_1   = prctile(eta_hat_i_pair_1,   [2.5, 97.5]);

ci_k_pair_2     = prctile(k_hat_i_pair_2,   [2.5, 97.5]);
ci_sigma_pair_2 = prctile(sigma_hat_i_pair_2, [2.5, 97.5]);
ci_eta_pair_2   = prctile(eta_hat_i_pair_2,   [2.5, 97.5]);
fprintf('===Parameters for pair 1===\n');
print_MLE_CI(k_hat_pair_1, eta_hat_pair_1, sigma_hat_pair_1, alpha, ci_k_pair_1, ci_sigma_pair_1, ci_eta_pair_1, k_hat_i_pair_1, sigma_hat_i_pair_1, eta_hat_i_pair_1, 8)
fprintf('===Parameters for pair 1===\n');
print_MLE_CI(k_hat_pair_2, eta_hat_pair_2, sigma_hat_pair_2, alpha, ci_k_pair_2, ci_sigma_pair_2, ci_eta_pair_2, k_hat_i_pair_2, sigma_hat_i_pair_2, eta_hat_i_pair_2, 8)

%% Question G.C

l = -1.960;
f = 1;
c_vals = linspace(0.001, 1.00, 100);

[d_vals_pair_1, u_vals_pair_1, d_star_pair_1, u_star_pair_1, c_bar_pair_1, SIGMA_pair_1, theta_pair_1, expected_C_pair_1] = pair_futures(mid_RXA, mid_IKA, sigma_hat_pair_1, k_hat_pair_1, l, f, c_vals);
[d_vals_pair_2, u_vals_pair_2, d_star_pair_2, u_star_pair_2, c_bar_pair_2, SIGMA_pair_2, theta_pair_2, expected_C_pair_2] = pair_futures(mid_OATA, mid_OEA, sigma_hat_pair_2, k_hat_pair_2, l, f, c_vals);
 
 % === Plot risultati ===
 figure;
 plot(c_vals, -d_vals_pair_1, 'r-', 'LineWidth', 1.5); hold on;
 plot(c_vals, u_vals_pair_1, 'b--', 'LineWidth', 1.5); hold on;
 xline(c_bar_pair_1, 'green--', 'LineWidth', 1.5); hold on;
 x = [c_bar_pair_1,   c_bar_pair_1];
 y = [-d_star_pair_1, u_star_pair_1];
 plot(x, y, 'o', 'MarkerEdgeColor','c','MarkerFaceColor','c','LineWidth',1.5);
 xlabel('Transaction cost c (in S units)');
 ylabel('Optimal trading bands');
 legend('|d^*|','u^*','Location','NorthWest');
 title('Figure 3 – Optimal bands vs. transaction cost');
 grid on;

  % === Plot risultati ===
 figure;
 plot(c_vals, -d_vals_pair_2, 'r-', 'LineWidth', 1.5); hold on;
 plot(c_vals, u_vals_pair_2, 'b--', 'LineWidth', 1.5); hold on;
 xline(c_bar_pair_2, 'green--', 'LineWidth', 1.5); hold on;
 x = [c_bar_pair_2,   c_bar_pair_2];
 y = [-d_star_pair_2, u_star_pair_2];
 plot(x, y, 'o', 'MarkerEdgeColor','c','MarkerFaceColor','c','LineWidth',1.5);
 xlabel('Transaction cost c (in S units)');
 ylabel('Optimal trading bands');
 legend('|d^*|','u^*','Location','NorthWest');
 title('Figure 3 – Optimal bands vs. transaction cost');
 grid on;


flag = 2;
[Rt_pair_1_IS_filtered, Rt_OS_1_Filtered] = filter_NY(time_new_IS_cleaned, time_new_OS, Rt_pair_1_IS_cleaned, Rt_pair_1_OS, 17, 20, flag);
[Rt_pair_2_IS_filtered, Rt_OS_2_Filtered] = filter_NY(time_new_IS_cleaned, time_new_OS, Rt_pair_2_IS_cleaned, Rt_pair_2_OS, 17, 20, flag);
 
 %% testing on OS dataset

flag = 1;
n = 6;

[X_OS_pair_1, value_pair_1, ann_pct_return_pair_1] = long_run_futures(Rt_OS_1_Filtered, eta_hat_pair_1, theta_pair_1, SIGMA_pair_1, u_star_pair_1, d_star_pair_1, l, c_bar_pair_1, f);

[X_OS_pair_2, value_pair_2, ann_pct_return_pair_2] = long_run_futures(Rt_OS_2_Filtered, eta_hat_pair_2, theta_pair_2, SIGMA_pair_2, u_star_pair_2, d_star_pair_2, l, c_bar_pair_2, f);


 
%% G.D

%let's try with some leverage
f_max = 20;
[opt_lev_pair_1, rtn_pair_1, mu_vector_pair_1] = run_leverage(X_OS_pair_1, SIGMA_pair_1, theta_pair_1, c_bar_pair_1, l, f_max, sigma_hat_i_pair_1, k_hat_i_pair_1, expected_C_pair_1, d_star_pair_1, u_star_pair_1, value_pair_1);

[opt_lev_pair_2, rtn_pair_2, mu_vector_pair_2] = run_leverage(X_OS_pair_2, SIGMA_pair_2, theta_pair_2, c_bar_pair_2, l, f_max, sigma_hat_i_pair_2, k_hat_i_pair_2, expected_C_pair_2, d_star_pair_2, u_star_pair_2, value_pair_2);

%% G.E

[ann_return_vector_pair_1] = run_stop_loss(X_OS_pair_1, d_star_pair_1, u_star_pair_1, c_bar_pair_1, SIGMA_pair_1, theta_pair_1);


[ann_return_vector_pair_2] = run_stop_loss(X_OS_pair_2, d_star_pair_2, u_star_pair_2, c_bar_pair_2, SIGMA_pair_2, theta_pair_2);