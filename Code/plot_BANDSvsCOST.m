function plot_BANDSvsCOST(c_vals, d_vals, u_vals, c_bar, d_star, u_star, flag)
 if flag==1
    figure;
    plot(c_vals, -d_vals, 'r-', 'LineWidth', 1.5); hold on;
    plot(c_vals, u_vals, 'b--', 'LineWidth', 1.5);
    xlabel('Transaction cost c (in S units)');
    ylabel('Optimal trading bands');
    legend('|d^*|','u^*','Location','NorthWest');
    title('Figure 3 – Optimal bands vs. transaction cost');
    grid on;
end
if flag==2
    figure;
    plot(c_vals, -d_vals, 'r-', 'LineWidth', 1.5); hold on;
    plot(c_vals, u_vals, 'b--', 'LineWidth', 1.5); hold on;
    xline(c_bar, 'green--', 'LineWidth', 1.5); hold on;
    x = [c_bar,   c_bar];
    y = [-d_star, u_star];
    hold on
    plot(x, y, 'o', 'MarkerEdgeColor','c','MarkerFaceColor','c','LineWidth',1.5);
    xlabel('Transaction cost c (in S units)');
    ylabel('Optimal trading bands');
    legend('|d^*|','u^*','Location','NorthWest');
    title('Figure 3 – Optimal bands vs. transaction cost');
    grid on;
    exportgraphics(gcf, 'theoreticalbands.pdf');
 end
end