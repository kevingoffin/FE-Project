function plot_XOS(X_OS, d_star, u_star, l)
figure;
plot(X_OS, 'black'); hold on;
yline(d_star, "green", 'LineWidth', 1.5); hold on;
yline(u_star, "blue", 'LineWidth', 1.5);

yline(-d_star, "black", 'LineWidth', 1.5); hold on;
yline(-u_star, "cyan", 'LineWidth', 1.5);
yline(l, "red", 'LineWidth', 1.5)
yline(-l, "red", 'LineWidth', 1.5)
xlabel('time');
ylabel('log-price process');
legend('OU process', 'd*','u*','stop loss');
title('Trading strategy');
end