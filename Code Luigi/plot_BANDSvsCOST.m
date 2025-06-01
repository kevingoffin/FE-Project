function plot_BANDSvsCOST(c_vals, d_vals, u_vals, flag, c_bar, d_star, u_star)
    % PLOT_BANDSVSCOST Visualizes optimal trading bands vs transaction costs
    %
    % Inputs:
    %   c_vals  - Array of transaction cost values (in sigma units)
    %   d_vals  - Optimal lower band (entry level) for each cost
    %   u_vals  - Optimal upper band (exit level) for each cost
    %   c_bar   - Critical transaction cost threshold
    %   d_star  - Optimal lower band at critical cost c_bar
    %   u_star  - Optimal upper band at critical cost c_bar
    %   flag    - Boolean to select plot style (true = basic, false = annotated)
    
    if flag
        % === BASIC PLOT (without critical cost annotation) ===
        figure;
        % Plot absolute value of lower band (d is negative, so we plot -d)
        plot(c_vals, -d_vals, 'r-', 'LineWidth', 1.5); 
        hold on;
        % Plot upper band
        plot(c_vals, u_vals, 'b--', 'LineWidth', 1.5);
        
        % Formatting
        xlabel('Transaction cost c (in \Sigma units)');
        ylabel('Optimal trading bands');
        legend('|d^*|','u^*','Location','NorthWest');
        title('Optimal bands vs. transaction cost');
        grid on;
        
    else
        % === ANNOTATED PLOT (with critical cost markers) ===
        figure;
        % Plot absolute value of lower band
        plot(c_vals, -d_vals, 'r-', 'LineWidth', 1.5); 
        hold on;
        % Plot upper band
        plot(c_vals, u_vals, 'b--', 'LineWidth', 1.5);
        
        % Add vertical line at critical transaction cost
        xline(c_bar, 'green--', 'LineWidth', 1.5);
        
        % Mark optimal bands at critical cost with cyan circles
        x = [c_bar,   c_bar];       % X-coordinates (at c_bar)
        y = [-d_star, u_star];      % Y-coordinates (optimal bands)
        plot(x, y, 'o', 'MarkerEdgeColor','c','MarkerFaceColor','c','LineWidth',1.5);
        
        % Formatting
        xlabel('Transaction cost c (in \Sigma units)');
        ylabel('Optimal trading bands');
        legend('|d^*|','u^*','Location','NorthWest');
        title('Optimal bands vs. transaction cost');
        grid on;
        
        % Export figure to PDF (for publications/thesis)
        exportgraphics(gcf, 'theoreticalbands.pdf');
    end
end