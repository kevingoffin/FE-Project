clear; clc;
close all
format long
%%

% Leggi il file Excel (salta le prime due righe di intestazione)
opts = detectImportOptions('KO_PEP.xlsx', 'Sheet', 'KO');
opts.DataRange = 'A2'; % Inizia dalla riga 3
T = readtable('KO_PEP.xlsx', opts);

% Estrai le colonne di interesse
% Timestamp, Bid HO, Ask HO, Bid LGO, Ask LGO
timestamp = T{:, 1};      % Timestamp
high_XLE    = T{:, 3};      % high HO
low_XLE   = T{:, 4};      % low LGO
high_XOP    = T{:, 9};      % high HO
low_XOP  = T{:, 10};      % low LGO

% Filtra righe valide (dove tutti i dati sono disponibili)
valid_idx = ~isnan(high_XLE ) & ~isnan(low_XLE) & ~isnan(high_XOP) & ~isnan(low_XOP);
timestamp = timestamp(valid_idx);
high_XLE = high_XLE(valid_idx);
low_XLE = low_XLE(valid_idx);
high_XOP = 0.5.* high_XOP(valid_idx);
low_XOP = 0.5.*low_XOP(valid_idx);

mid_XLE = 0.5*(high_XLE + low_XLE);
mid_XOP = 0.5*(high_XOP + low_XOP);

Rt = log(mid_XLE./mid_XOP);

%%

[Rt_IS_cleaned, Rt_OS, time_IS_cleaned, time_OS] = cleaner(Rt, timestamp, 48);

deltaT = 1/252;
[eta_hat, k_hat, sigma_hat] = calibration(Rt_IS_cleaned, deltaT, 2);


[opt_lev] = optimalLeverage(SIGMA, theta, c_bar, l, 100);

%%
Rt_0 = Rt_IS_cleaned;
n_sim = 10000;
rng(42);

[sigma_hat_i, k_hat_i, eta_hat_i] = simulation(Rt_0, n_sim, deltaT, eta_hat, k_hat, sigma_hat);

alpha = 0.05;
% Confidence Intervals 95%
ci_k     = prctile(k_hat_i,     [2.5, 97.5]);
ci_sigma = prctile(sigma_hat_i, [2.5, 97.5]);
ci_eta   = prctile(eta_hat_i,   [2.5, 97.5]);


figure; histogram(k_hat_i,100,'Normalization','pdf'); title('k\_hat');
xline(ci_k(1), 'r-', sprintf('%.2f%% = %.3f',100*alpha/2, ci_k(1)), ...
      'LineWidth',2, 'LabelHorizontalAlignment','left');
xline(ci_k(2), 'r-', sprintf('%.2f%% = %.3f',100*(1-alpha/2), ci_k(2)), ...
      'LineWidth',2, 'LabelHorizontalAlignment','right');
figure; histogram(sigma_hat_i,100,'Normalization','pdf'); title('\sigma\_hat');
xline(ci_sigma(1), 'r-', sprintf('%.2f%% = %.3f',100*alpha/2, ci_sigma(1)), ...
      'LineWidth',2, 'LabelHorizontalAlignment','left');
xline(ci_sigma(2), 'r-', sprintf('%.2f%% = %.3f',100*(1-alpha/2), ci_sigma(2)), ...
      'LineWidth',2, 'LabelHorizontalAlignment','right');
figure; histogram(eta_hat_i,100,'Normalization','pdf');  title('\eta\_hat');
xline(ci_eta(1), 'r-', sprintf('%.2f%% = %.3f',100*alpha/2, ci_eta(1)), ...
      'LineWidth',2, 'LabelHorizontalAlignment','left');
xline(ci_eta(2), 'r-', sprintf('%.2f%% = %.3f',100*(1-alpha/2), ci_eta(2)), ...
      'LineWidth',2, 'LabelHorizontalAlignment','right');

fprintf('===MLE Parameters===\n')
fprintf('k_MLE:   %.15f\n', k_hat);
fprintf('eta_MLE:   %.15f\n', eta_hat);
fprintf('sigma_MLE:   %.15f\n', sigma_hat);

fprintf('===Confidence intervals for 8-16===\n')
fprintf('95%% CI per k_hat :     [%.15f, %.15f]\n', ci_k(1),     ci_k(2));
fprintf('95%% CI per sigma_hat: [%.15f, %.15f]\n', ci_sigma(1), ci_sigma(2));
fprintf('95%% CI per eta_hat:   [%.15f, %.15f]\n', ci_eta(1),   ci_eta(2));


%%
f = 1;
l = -1.960;
c_vals = linspace(0.001, 1.00, 100);

[d_vals, u_vals, d_star, u_star, c_bar, SIGMA, theta, expected_C] = pair_futures(mid_XLE, mid_XOP, sigma_hat, k_hat, l, f, c_vals);

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

 %%
 flag = 2;
 n = 1;
 [X_OS, value, ann_pct_return] = long_run_futures(Rt_OS, eta_hat, theta, SIGMA, u_star, d_star, l, c_bar, f, flag, n);
