function print_MLE_CI(k_hat, eta_hat, sigma_hat, alpha, ci_k, ci_sigma, ci_eta,k_hat_i, sigma_hat_i, eta_hat_i, start)
figure; histogram(k_hat_i,100,'Normalization','pdf'); title('Distribution of $\hat{k}$', 'Interpreter', 'latex', 'FontSize', 14);
xline(ci_k(1), 'r-', sprintf('%.2f%% = %.3f',100*alpha/2, ci_k(1)), ...
      'LineWidth',2, 'LabelHorizontalAlignment','left');
xline(ci_k(2), 'r-', sprintf('%.2f%% = %.3f',100*(1-alpha/2), ci_k(2)), ...
      'LineWidth',2, 'LabelHorizontalAlignment','right');
figure; histogram(sigma_hat_i,100,'Normalization','pdf'); title('Distribution of $\hat{\sigma}$', 'Interpreter', 'latex', 'FontSize', 14);
xline(ci_sigma(1), 'r-', sprintf('%.2f%% = %.3f',100*alpha/2, ci_sigma(1)), ...
      'LineWidth',2, 'LabelHorizontalAlignment','left');
xline(ci_sigma(2), 'r-', sprintf('%.2f%% = %.3f',100*(1-alpha/2), ci_sigma(2)), ...
      'LineWidth',2, 'LabelHorizontalAlignment','right');
figure; histogram(eta_hat_i,100,'Normalization','pdf');  title('Distribution of $\hat{\eta}$', 'Interpreter', 'latex', 'FontSize', 14);
xline(ci_eta(1), 'r-', sprintf('%.2f%% = %.3f',100*alpha/2, ci_eta(1)), ...
      'LineWidth',2, 'LabelHorizontalAlignment','left');
xline(ci_eta(2), 'r-', sprintf('%.2f%% = %.3f',100*(1-alpha/2), ci_eta(2)), ...
      'LineWidth',2, 'LabelHorizontalAlignment','right');

fprintf('===MLE Parameters===\n')
fprintf('k_MLE:   %.15f\n', k_hat);
fprintf('eta_MLE:   %.15f\n', eta_hat);
fprintf('sigma_MLE:   %.15f\n', sigma_hat);

fprintf('===Confidence intervals for %.0f-16===\n', start)
fprintf('95%% CI per k_hat:     [%.15f, %.15f]\n', ci_k(1),     ci_k(2));
fprintf('95%% CI per eta_hat:   [%.15f, %.15f]\n', ci_eta(1),   ci_eta(2));
fprintf('95%% CI per sigma_hat: [%.15f, %.15f]\n', ci_sigma(1), ci_sigma(2));
end