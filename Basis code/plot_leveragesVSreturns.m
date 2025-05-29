function plot_leveragesVSreturns(f, rtn, opt_lev, mu_vector)
    figure;
    plot(f, rtn*100); 
    xline(1);
    xline(2);
    xline(5);
    xline(opt_lev, "red", 'LineWidth', 1.5);
    xlabel('leverage levels');
    ylabel('OS return');
    title('Empirical returns leveraged');
    grid on;
    
    
    figure;
    plot(f, mu_vector); hold on;
    xline(1);
    xline(2);
    xline(5);
    xline(opt_lev, "red", 'LineWidth', 1.5);
    xlabel('leverage levels');
    ylabel('leveraged returns');
    title('Theoretical returns leveraged');
    grid on;
end