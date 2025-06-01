function plot_XOS(X_OS, d_star, u_star, l)
    % PLOT_XOS Visualizes the out-of-sample (OOS) spread process with trading bands
    %
    % Inputs:
    %   X_OS    - Out-of-sample log-price spread process (vector)
    %   d_star  - Optimal lower trading threshold (long entry trigger)
    %   u_star  - Optimal upper trading threshold (short entry trigger)
    %   l       - Stop-loss level (absolute value)
    %
    % Output:
    %   Figure showing:
    %   - The spread process evolution
    %   - Trading bands (±d*, ±u*)
    %   - Stop-loss levels (±l)
    %   - Legend identifying all elements

    % Create new figure with white background
    figure('Color', 'white');
    
    % === 1. Plot Spread Process ===
    plot(X_OS, 'black', 'LineWidth', 1.2); 
    hold on;
    grid on;
    
    % === 2. Plot Trading Bands ===
    % Positive thresholds
    yline(u_star, "blue", 'LineWidth', 1.5, 'Label', 'u* (short entry)'); 
    yline(d_star, "green", 'LineWidth', 1.5, 'Label', 'd* (long entry)');
    
    % Negative thresholds (symmetric strategy)
    yline(-u_star, "cyan", 'LineWidth', 1.5, 'Label', '-u*'); 
    yline(-d_star, "black", 'LineWidth', 1.5, 'Label', '-d*');
    
    % === 3. Plot Stop-Loss Levels ===
    yline(l, "red", '--', 'LineWidth', 1.5, 'Label', 'Stop loss'); 
    yline(-l, "red", '--', 'LineWidth', 1.5);
    
    % === 4. Formatting ===
    xlabel('Time (trading periods)', 'FontSize', 12);
    ylabel('Log-Price Spread (X_{OS})', 'FontSize', 12);
    title('Pairs Trading Strategy: Out-of-Sample Performance', 'FontSize', 14);
    
    % Custom legend showing all critical levels
    legend({'Spread Process', 'u* (short entry)', 'd* (long entry)', ...
            '-u*', '-d*', 'Stop loss'}, ...
            'Location', 'northeast', 'FontSize', 10);
    
    % Adjust axes for better visibility of thresholds
    ylim([min(-u_star*1.1, min(X_OS)*1.1), max(u_star*1.1, max(X_OS)*1.1)]);
end