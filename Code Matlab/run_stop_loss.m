function [ann_return_vector] = run_stop_loss(X_OS, c_bar, SIGMA, theta, l_vector, f, scaling_factor, w0, verbose_optimizedReturned)
    % RUN_STOP_LOSS Evaluates strategy performance across different stop-loss levels
    % and visualizes the results.
    %
    % Inputs:
    %   X_OS    : Normalized out-of-sample spread process (mean-reverting series)
    %   c_bar   : Normalized transaction cost (expected cost divided by SIGMA)
    %   SIGMA   : Stationary volatility of the OU process
    %   theta   : Mean-reversion timescale (1/k_hat)
    %
    % Output:
    %   ann_return_vector : Annualized returns for each stop-loss level tested
    %
    % The function:
    % 1. Tests multiple stop-loss thresholds (in standard deviation units)
    % 2. Computes annualized returns for each threshold
    % 3. Plots performance vs stop-loss levels
    % 4. Visualizes stop-loss thresholds on the price process

    % === 1. Define Stop-Loss Levels to Test ===
    % Values correspond to standard deviations for:
    % -1.282: 10% tail (90% confidence)
    % -1.645: 5% tail (95% confidence)
    % -1.96:  2.5% tail (97.5% confidence)
    % -2.326: 1% tail (99% confidence)

    % === 2. Compute Annualized Returns for Each Stop-Loss ===
    ann_return_vector = zeros(length(l_vector), 1);
    for i = 1:length(l_vector)
        % Calculate optimal trading bands (u*, d*) for current stop-loss
        [u_star, d_star, ~] = bands(c_bar, l_vector(i), SIGMA, theta, f);
        
        % Simulate strategy performance with current thresholds
        % Multiplier 6 converts to annualized returns (assuming 6-month period)
        ann_return_vector(i) = optimizedReturn(X_OS, d_star, u_star, l_vector(i), c_bar, SIGMA, f, scaling_factor, w0, verbose_optimizedReturned);
    end

    % === 3. Plot Performance vs Stop-Loss Levels ===
    figure;
    plot(l_vector, ann_return_vector, 'LineWidth', 2);
    grid on;
    xlabel('Stop-Loss Level (standard deviations)');
    ylabel('Annualized Return (%)');
    title('Strategy Performance vs Stop-Loss Threshold');
    
    % === 4. Visualize Stop-Losses on Price Process ===
    figure;
    plot(X_OS, 'black', 'LineWidth', 1.5); 
    hold on;
    
    % Plot stop-loss levels with descriptive labels
    yline(-1.282, '--r', '10% Tail (1.282σ)', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
    yline(-1.645, '--r', '5% Tail (1.645σ)', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
    yline(-1.96, '--r', '2.5% Tail (1.96σ)', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
    yline(-2.326, '--r', '1% Tail (2.326σ)', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');
    
    % Format plot
    xlabel('Time (periods)');
    ylabel('Normalized Spread');
    legend('Spread Process', 'Stop-Loss Levels', 'Location', 'northeast');
    title('Stop-Loss Thresholds on Price Process');
    grid on;
end