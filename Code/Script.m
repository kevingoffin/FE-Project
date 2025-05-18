clear; clc;
format long

%% Question b
% Read the excel
opts = detectImportOptions('HO-LGO.xlsm', 'Sheet', 'HO-LGO 30min');
opts.DataRange = 'A3'; % Starts at the row 3
T = readtable('HO-LGO.xlsm', opts);

% Take the columns of interest
% Timestamp, Bid HO, Ask HO, Bid LGO, Ask LGO
timestamp = T{:, 2};      % Timestamp
bid_HO    = T{:, 3};      % Bid HO
bid_LGO   = T{:, 4};      % Bid LGO
ask_HO    = T{:, 7};      % Ask HO
ask_LGO   = T{:, 8};      % Ask LGO

% Filter valid rows (where all data is available)
valid_idx = ~isnan(bid_HO) & ~isnan(ask_HO) & ~isnan(bid_LGO) & ~isnan(ask_LGO);
timestamp = timestamp(valid_idx);
bid_HO = bid_HO(valid_idx);
ask_HO = ask_HO(valid_idx);
bid_LGO = bid_LGO(valid_idx);
ask_LGO = ask_LGO(valid_idx);

% Compute the mid-price
mid_HO = (bid_HO + ask_HO) / 2;
mid_LGO = (bid_LGO + ask_LGO) / 2;
conv = 314;   % converter
mid_HO = mid_HO * conv;  

% Compute Rt
Rt = log(mid_HO ./ mid_LGO);

% Remove the outliers and split the dataset in IS and OS with 9 months in
% IS
border_IS_OS = calmonths(9);
Input_Format = 'yyyy-MM-dd HH:mm:ss';
verbose = true;
threshold_AntipersistentOutliers = 0.95;
[Rt_IS, Rt_OS, time_IS, time_OS] = cleaner(Rt, timestamp, border_IS_OS, Input_Format, threshold_AntipersistentOutliers, verbose);
%% Converting data to NY time 9:00-16:00
% 1) Convert the time in the New-York time-zone
time_IS_NY = time_IS;
time_IS_NY.TimeZone = 'Europe/Rome';
time_IS_NY.TimeZone = 'America/New_York';

time_OS_NY = time_OS;
time_OS_NY.TimeZone = 'Europe/Rome';
time_OS_NY.TimeZone = 'America/New_York';

% Keep the dates in the time window 9:00-16:00
hour_beginning = 9; hour_ending = 16;
flag = true;
[Rt_IS_9_16, Rt_OS_9_16] = filter_time_window(time_IS_NY, time_OS_NY, Rt_IS, Rt_OS, hour_beginning, hour_ending, flag);

% Convert the table in an array
Rt_IS_9_16 = table2array(Rt_IS_9_16(:, 2));

% Calibration
deltaT = 1/9072;
[eta_hat, k_hat, sigma_hat] = calibration(Rt_IS_9_16, deltaT);

fprintf('===Parameters values for 9-16===\n')
fprintf('k_hat = %d \n', eta_hat);
fprintf('sigma_hat = %d \n', k_hat);
fprintf('eta_hat = %d \n', sigma_hat);

% Process simulation
n_sim = 1e4;
rng(42);

[sigma_hat_i, k_hat_i, eta_hat_i] = simulation(Rt_IS_9_16, n_sim, deltaT, eta_hat, k_hat, sigma_hat);

figure; histogram(k_hat_i,100,'Normalization','pdf'); title('k\_hat');
figure; histogram(sigma_hat_i,100,'Normalization','pdf'); title('\sigma\_hat');
figure; histogram(eta_hat_i,100,'Normalization','pdf');  title('\eta\_hat');


% Confidence Intervals 95%
ci_k     = prctile(k_hat_i,     [2.5, 97.5]);
ci_sigma = prctile(sigma_hat_i, [2.5, 97.5]);
ci_eta   = prctile(eta_hat_i,   [2.5, 97.5]);

fprintf('===Confidence intervals for 9-16===\n')
fprintf('95%% CI per k_hat:     [%.15f, %.15f]\n', ci_k(1),     ci_k(2));
fprintf('95%% CI per sigma_hat: [%.15f, %.15f]\n', ci_sigma(1), ci_sigma(2));
fprintf('95%% CI per eta_hat:   [%.15f, %.15f]\n', ci_eta(1),   ci_eta(2));



%% Repeting with 8:00-16:00 NYT
flag = 1;

[Rt_IS_NY_Filtered, Rt_OS_NY_Filtered] = filter_NY(time_IS_NY, time_OS_NY, Rt_IS_filtered, Rt_OS_filtered, 8, 16, flag);

% Calibration
[eta_hat, k_hat, sigma_hat] = calibration(Rt_IS_NY_Filtered, deltaT, 1);

% Process simulation

Rt_0 = table2array(Rt_IS_NY_Filtered(:, 2));
n_sim = 1e4;
rng(42);

[sigma_hat_i, k_hat_i, eta_hat_i] = simulation(Rt_0, n_sim, deltaT, eta_hat, k_hat, sigma_hat);

figure; histogram(k_hat_i,100,'Normalization','pdf'); title('k\_hat');
figure; histogram(sigma_hat_i,100,'Normalization','pdf'); title('\sigma\_hat');
figure; histogram(eta_hat_i,100,'Normalization','pdf');  title('\eta\_hat');


% Confidence Intervals 95%
ci_k     = prctile(k_hat_i,     [2.5, 97.5]);
ci_sigma = prctile(sigma_hat_i, [2.5, 97.5]);
ci_eta   = prctile(eta_hat_i,   [2.5, 97.5]);

fprintf('===Confidence intervals for 8-16===\n')
fprintf('95%% CI per k_hat :     [%.15f, %.15f]\n', ci_k(1),     ci_k(2));
fprintf('95%% CI per sigma_hat: [%.15f, %.15f]\n', ci_sigma(1), ci_sigma(2));
fprintf('95%% CI per eta_hat:   [%.15f, %.15f]\n', ci_eta(1),   ci_eta(2));

%% Question C
flag = 2;
[bid_HO_IS_filtered, bid_HO_OS_filtered, time_IS_filtered, time_OS_filtered] = cleaner(bid_HO, timestamp, 9);
[ask_HO_IS_filtered, ask_HO_OS_filtered, time_IS_filtered, time_OS_filtered] = cleaner(ask_HO, timestamp, 9);
[bid_LGO_IS_filtered, bid_LGO_OS_filtered, time_IS_filtered, time_OS_filtered] = cleaner(bid_LGO, timestamp, 9);
[ask_LGO_IS_filtered, ask_LGO_OS_filtered, time_IS_filtered, time_OS_filtered] = cleaner(ask_LGO, timestamp, 9);
[bid_HO_IS_NY_Filtered, bid_HO_OS_NY_Filtered] = filter_NY(time_IS_NY, time_OS_NY, bid_HO_IS_filtered, bid_HO_OS_filtered, 17, 20, flag);
[ask_HO_IS_NY_Filtered, ask_HO_OS_NY_Filtered] = filter_NY(time_IS_NY, time_OS_NY, ask_HO_IS_filtered, ask_HO_OS_filtered, 17, 20, flag);
[bid_LGO_IS_NY_filtered, bid_LGO_OS_NY_filtered] = filter_NY(time_IS_NY, time_OS_NY, bid_LGO_IS_filtered, bid_LGO_OS_filtered, 17, 20, flag);
[ask_LGO_IS_NY_filtered, ask_LGO_OS_NY_filtered] = filter_NY(time_IS_NY, time_OS_NY, ask_LGO_IS_filtered, ask_LGO_OS_filtered, 17, 20, flag);


C = log(table2array(ask_HO_IS_NY_Filtered(:,2))./table2array(bid_HO_IS_NY_Filtered(:,2))) + log(table2array(ask_LGO_IS_NY_filtered(:,2))./table2array(bid_LGO_IS_NY_filtered(:,2)));
expected_C = mean(C);
SIGMA=sigma_hat/sqrt(2*k_hat);
c_bar = expected_C/SIGMA;


% === Stop-loss fisso (in unità di S) ===
l = -1.645;

% === Costi di transazione (in unità di S) ===
c_vals = linspace(0.001, 0.75, 100);

flag = 2;

[d_vals, u_vals] = maximize_mu(c_vals, l, SIGMA, 1/k_hat, flag, 1);


[~, idx] = min(abs(c_vals - c_bar));

d_star = d_vals(idx);
u_star = u_vals(idx);

% === Plot risultati ===
figure;
plot(c_vals, -d_vals, 'r-', 'LineWidth', 1.5); hold on;
plot(c_vals, u_vals, 'b--', 'LineWidth', 1.5); hold on;
xline(c_bar, 'green--', 'LineWidth', 1.5); hold on;
x = [c_bar,   c_bar];
y = [-d_star, u_star];
plot(x, y, 'o', 'MarkerEdgeColor','c','MarkerFaceColor','c','LineWidth',1.5);
xlabel('Transaction cost c (in S units)');
ylabel('Optimal trading bands');
legend('|d^*|','u^*','Location','NorthWest');
title('Figure 3 – Optimal bands vs. transaction cost');
grid on;

flag = 2;

[Rt_IS_NY_Filtered, Rt_OS_NY_Filtered] = filter_NY(time_IS_NY, time_OS_NY, Rt_IS_filtered, Rt_OS_filtered, 17, 20, flag);


% Theoric result

f = 1;
theta = 1/k_hat;
erfid = @(x, y) erfi(x./sqrt(2)) - erfi(y./sqrt(2));
mu = @(d, u, c) (1/(theta*pi))*((log(1+f*(exp(SIGMA*(u - d - c))-1)) ./ erfid(u, d)) + ((log(1+f*(exp(SIGMA*(l - d - c))-1)) ./ erfid(d, l))));

% % 1) Genera u_i e d_i
% [d_samples, u_samples] = simulation_ci(sigma_hat_i, k_hat_i, eta_hat_i, c_bar, l, 1/k_hat, f);
% 
% % 2) Calcola CI al 95%
% mu_d=mean(d_samples);
% std_d=std(d_samples);
% alpha=0.05;
% lower=mu_d-norminv(0.975)*std_d/sqrt(n_sim);
% upper=mu_d+norminv(0.975)*std_d/sqrt(n_sim);
% ci_u = prctile(u_samples, [2.5,97.5]);
% 
% fprintf('95%% CI per d*: [%.15f, %.15f]\n', ci_d(1), ci_d(2));
% fprintf('95%% CI per u*: [%.15f, %.15f]\n', ci_u(1), ci_u(2));
% fprintf('Optimal value for d* and u*: [%.15f, %.15f]\n', d_star, u_star);


%% testing on OS dataset

X_OS = (table2array(Rt_OS_NY_Filtered(:,2)) - eta_hat) / SIGMA; 
figure;
plot(X_OS, 'black'); hold on;
yline(d_star, "green", 'LineWidth', 1.5); hold on;
yline(u_star, "blue", 'LineWidth', 1.5);
yline(l, "red", 'LineWidth', 1.5)
xlabel('time');
ylabel('log-price process');
legend('OU process', 'd*','u*','stop loss');
title('title');

erfid = @(x, y) erfi(x./sqrt(2)) - erfi(y./sqrt(2));
p_pls = erfid(d_star, l)/erfid(u_star,l);
p_mns = erfid(u_star, d_star)/erfid(u_star,l);
c_max = p_pls*(u_star - l) - (d_star - l);

[ann_pct_return] = billionaire(X_OS, d_star, u_star, l, c_bar, Rt_OS_NY_Filtered, SIGMA);
[ann_pct_return_cmax] = billionaire(X_OS, d_star, u_star, l, c_max, Rt_OS_NY_Filtered, SIGMA);

fprintf('probabilities and sum [%.6f, %.6f, %.6f]\n', p_pls,  p_mns, p_pls + p_mns)
fprintf('Expected theorical result over 1 year %.6f %% \n', mu(d_star, u_star, c_bar)*100)
fprintf('Expected theorical result over 3 month %.6f %% \n', mu(d_star, u_star, c_bar)*1/4*100)
fprintf('actual transaction cost normalized %.6f\n', c_bar)
fprintf('Actual result over 3 month %.6f %%\n', ann_pct_return)
fprintf('maximum transaction cost normalized %.6f\n', c_max)
fprintf('Actual result over 3 month with maximum transaction costs %.6f %%\n', ann_pct_return_cmax)

%% Question a
% === Parameters OU ===
theta = 0.041;
%sigma = 0.0147;   % diffusion parameter
% WHY NOT SIGMA ??????

% === Stop-loss level (in unit of steady-state standard deviation for the OU dynamics) ===
l = -1.960;

% === Cost of transaction (in unit of steady-state standard deviation for the OU dynamics) ===
c_vals = linspace(0.001, 0.75, 100);
f = 1; % No leverage assumption

[d_vals, u_vals] = maximize_mu(c_vals, l, SIGMA, theta, f);

% === Plot results ===
figure;
plot(c_vals, -d_vals, 'r-', 'LineWidth', 1.5); hold on;
plot(c_vals, u_vals, 'b--', 'LineWidth', 1.5);
xlabel('Transaction cost c (in S units)');
ylabel('Optimal trading bands');
legend('|d^*|','u^*','Location','NorthWest');
title('Figure 3 – Optimal bands vs. transaction cost');
grid on;

%% Question D

%let's try with some leverage

[opt] = f_opt(u_star, d_star, l, c_bar, SIGMA, p_pls, p_mns);
mu_vector = zeros(50,1);

for f=1:50
    theta = 1/k_hat;
    erfid = @(x, y) erfi(x./sqrt(2)) - erfi(y./sqrt(2));
    mu = @(d, u, c) (1/(theta*pi))*((log(1+f*(exp(SIGMA*(u - d - c))-1)) ./ erfid(u, d)) + ((log(1+f*(exp(SIGMA*(l - d - c))-1)) ./ erfid(d, l))));
    mu_vector( ...
        f) = mu(d_star, u_star, c_bar)*100;
    %fprintf('Expected theorical result over 1 year %.6f %% \n', mu(d_star, u_star, c_bar)*100)
end
figure;
plot(mu_vector); hold on;
xline(1);
xline(2);
xline(5);
xline(opt, "red", 'LineWidth', 1.5);
xlabel('leverage levels');
ylabel('leveraged returns');

title('title');
grid on;

%% E

l_vector = [-1.282, -1.645, -1.96, -2.326];
for i=1:length(l_vector)
    ann_pct_return_vector(i) = billionaire(X_OS, d_star, u_star, l_vector(i), c_bar, Rt_OS_NY_Filtered, SIGMA);
end
figure;
plot(l_vector, ann_pct_return_vector)
grid on;
figure;
plot(X_OS, 'black'); hold on;
yline(d_star, "green", 'LineWidth', 1.5); hold on;
yline(u_star, "blue", 'LineWidth', 1.5);
yline(-1.282, "red", 'LineWidth', 1.5)
yline( -1.645, "red", 'LineWidth', 1.5)
yline(-1.96, "red", 'LineWidth', 1.5)
yline(-2.326, "red", 'LineWidth', 1.5)

xlabel('time');
ylabel('log-price process');
legend('OU process', 'd*','u*','stop losses');
title('title');

%% G

opts_new = detectImportOptions('GovernativeFutures.xlsx', 'Sheet', 'sheet1');
opts_new.DataRange = 'A1'; % Inizia dalla riga 1
T_new = readtable('GovernativeFutures.xlsx', opts_new);

timestamp_new = T_new{:, 1};
mid_IKA    = T_new{:, 2};   
mid_OATA   = T_new{:, 3};  
mid_OEA    = T_new{:, 4};  
mid_RXA   = T_new{:, 5};   

valid_idx_new = ~isnan(mid_IKA) & ~isnan(mid_OATA) &  ~isnan(mid_OEA) & ~isnan(mid_RXA) ;
timestamp_new = timestamp_new(valid_idx_new);
mid_IKA = mid_IKA(valid_idx_new);
mid_OATA = mid_OATA(valid_idx_new);
mid_OEA = mid_OEA(valid_idx_new);
mid_RXA = mid_RXA(valid_idx_new);

Rt_pair_1 = log(mid_IKA./mid_OATA);       % pair IKA, OATA
Rt_pair_2 = log(mid_OEA./mid_RXA);        % pair OEA, RXA

deltaT_new = 1/(252*48*30);
[Rt_pair_1_IS_filtered, ~, time_new_IS_filtered, ~] = cleaner(Rt_pair_1, timestamp_new, 4);
[Rt_pair_2_IS_filtered, ~, time_new_IS_filtered, ~] = cleaner(Rt_pair_2, timestamp_new, 4);
[eta_hat_pair_1, k_hat_pair_1, sigma_hat_pair_1] = calibration(Rt_pair_1_IS_filtered, deltaT_new, 2);
[eta_hat_pair_2, k_hat_pair_2, sigma_hat_pair_2] = calibration(Rt_pair_2_IS_filtered, deltaT_new, 2);

%% Question G.C

bid_IKA_IS = mid_IKA - 0.005;
ask_IKA_IS = mid_IKA + 0.005;
bid_OATA_IS = mid_OATA - 0.005;
ask_OATA_IS = mid_OATA + 0.005;
bid_OEA_IS = mid_OEA - 0.005;
ask_OEA_IS = mid_OEA + 0.005;
bid_RXA_IS = mid_RXA - 0.005;
ask_RXA_IS = mid_RXA + 0.005;

C_pair_1 = log(ask_IKA_IS./bid_IKA_IS) + log(ask_OATA_IS./bid_OATA_IS);
C_pair_2 = log(ask_OEA_IS./bid_OEA_IS) + log(ask_RXA_IS./bid_RXA_IS);
expected_C_pair_1 = mean(C_pair_1);
expected_C_pair_2 = mean(C_pair_2);

SIGMA_pair_1=sigma_hat_pair_1/sqrt(2*k_hat_pair_1);
SIGMA_pair_2=sigma_hat_pair_2/sqrt(2*k_hat_pair_2);

c_bar_pair_1 = expected_C_pair_1/SIGMA_pair_1;
c_bar_pair_2 = expected_C_pair_2/SIGMA_pair_2;

% 
% % === Stop-loss fisso (in unità di S) ===
% l = -1.645;
% 
% % === Costi di transazione (in unità di S) ===
% c_vals = linspace(0.001, 0.75, 100);
% 
% flag = 2;
% 
% [d_vals, u_vals] = maximize_mu(c_vals, l, SIGMA, 1/k_hat, flag, 1);
% 
% 
% [~, idx] = min(abs(c_vals - c_bar));
% 
% d_star = d_vals(idx);
% u_star = u_vals(idx);
% 
% % === Plot risultati ===
% figure;
% plot(c_vals, -d_vals, 'r-', 'LineWidth', 1.5); hold on;
% plot(c_vals, u_vals, 'b--', 'LineWidth', 1.5); hold on;
% xline(c_bar, 'green--', 'LineWidth', 1.5); hold on;
% x = [c_bar,   c_bar];
% y = [-d_star, u_star];
% plot(x, y, 'o', 'MarkerEdgeColor','c','MarkerFaceColor','c','LineWidth',1.5);
% xlabel('Transaction cost c (in S units)');
% ylabel('Optimal trading bands');
% legend('|d^*|','u^*','Location','NorthWest');
% title('Figure 3 – Optimal bands vs. transaction cost');
% grid on;
% 
% flag = 2;
% 
% [Rt_IS_NY_Filtered, Rt_OS_NY_Filtered] = filter_NY(time_IS_NY, time_OS_NY, Rt_IS_filtered, Rt_OS_filtered, 17, 20, flag);
% 
% 
% % Theoric result
% 
% f = 1;
% theta = 1/k_hat;
% erfid = @(x, y) erfi(x./sqrt(2)) - erfi(y./sqrt(2));
% mu = @(d, u, c) (1/(theta*pi))*((log(1+f*(exp(SIGMA*(u - d - c))-1)) ./ erfid(u, d)) + ((log(1+f*(exp(SIGMA*(l - d - c))-1)) ./ erfid(d, l))));
% 
% 
% 
% %% testing on OS dataset
% 
% X_OS = (table2array(Rt_OS_NY_Filtered(:,2)) - eta_hat) / SIGMA; 
% figure;
% plot(X_OS, 'black'); hold on;
% yline(d_star, "green", 'LineWidth', 1.5); hold on;
% yline(u_star, "blue", 'LineWidth', 1.5);
% yline(l, "red", 'LineWidth', 1.5)
% xlabel('time');
% ylabel('log-price process');
% legend('OU process', 'd*','u*','stop loss');
% title('title');
% 
% erfid = @(x, y) erfi(x./sqrt(2)) - erfi(y./sqrt(2));
% p_pls = erfid(d_star, l)/erfid(u_star,l);
% p_mns = erfid(u_star, d_star)/erfid(u_star,l);
% c_max = p_pls*(u_star - l) - (d_star - l);
% 
% [ann_pct_return] = billionaire(X_OS, d_star, u_star, l, c_bar, Rt_OS_NY_Filtered, SIGMA);
% [ann_pct_return_cmax] = billionaire(X_OS, d_star, u_star, l, c_max, Rt_OS_NY_Filtered, SIGMA);
% 
% fprintf('probabilities and sum [%.6f, %.6f, %.6f]\n', p_pls,  p_mns, p_pls + p_mns)
% fprintf('Expected theorical result over 1 year %.6f %% \n', mu(d_star, u_star, c_bar)*100)
% fprintf('Expected theorical result over 3 month %.6f %% \n', mu(d_star, u_star, c_bar)*1/4*100)
% fprintf('actual transaction cost normalized %.6f\n', c_bar)
% fprintf('Actual result over 3 month %.6f %%\n', ann_pct_return)
% fprintf('maximum transaction cost normalized %.6f\n', c_max)
% fprintf('Actual result over 3 month with maximum transaction costs %.6f %%\n', ann_pct_return_cmax)
% 
% 
% %% G.D
% 
% %let's try with some leverage
% 
% [opt] = f_opt(u_star, d_star, l, c_bar, SIGMA, p_pls, p_mns);
% mu_vector = zeros(50,1);
% 
% for f=1:50
%     theta = 1/k_hat;
%     erfid = @(x, y) erfi(x./sqrt(2)) - erfi(y./sqrt(2));
%     mu = @(d, u, c) (1/(theta*pi))*((log(1+f*(exp(SIGMA*(u - d - c))-1)) ./ erfid(u, d)) + ((log(1+f*(exp(SIGMA*(l - d - c))-1)) ./ erfid(d, l))));
%     mu_vector(f) = mu(d_star, u_star, c_bar)*100;
%     %fprintf('Expected theorical result over 1 year %.6f %% \n', mu(d_star, u_star, c_bar)*100)
% end
% figure;
% plot(mu_vector); hold on;
% xline(1);
% xline(2);
% xline(5);
% xline(opt, "red", 'LineWidth', 1.5);
% xlabel('leverage levels');
% ylabel('leveraged returns');
% 
% title('title');
% grid on;
% 
% %% G.E
% 
% l_vector = [-1.282, -1.645, -1.96, -2.326];
% for i=1:length(l_vector)
%     ann_pct_return_vector(i) = billionaire(X_OS, d_star, u_star, l_vector(i), c_bar, Rt_OS_NY_Filtered, SIGMA);
% end
% figure;
% plot(l_vector, ann_pct_return_vector)
% grid on;
% figure;
% plot(X_OS, 'black'); hold on;
% yline(d_star, "green", 'LineWidth', 1.5); hold on;
% yline(u_star, "blue", 'LineWidth', 1.5);
% yline(-1.282, "red", 'LineWidth', 1.5)
% yline( -1.645, "red", 'LineWidth', 1.5)
% yline(-1.96, "red", 'LineWidth', 1.5)
% yline(-2.326, "red", 'LineWidth', 1.5)
% 
% xlabel('time');
% ylabel('log-price process');
% legend('OU process', 'd*','u*','stop losses');
% title('title');
