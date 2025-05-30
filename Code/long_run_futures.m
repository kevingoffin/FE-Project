function [X_OS, value, ann_return] = long_run_futures(Rt_OS, eta_hat, theta, SIGMA, u_star, d_star, l, c_bar, f, w0, scaling_factor, verbose, verbose_optimizedReturned)
    % LONG_RUN_FUTURES Simulates and evaluates a pairs trading strategy performance
    % on out-of-sample data, with visualization and key metric reporting.
    %
    % Inputs:
    %   Rt_OS    : Out-of-sample log price ratio (spread) series
    %   eta_hat  : Estimated mean of the spread process
    %   theta    : Mean-reversion timescale (1/k_hat)
    %   SIGMA    : Stationary volatility of the OU process
    %   u_star   : Optimal upper trading threshold
    %   d_star   : Optimal lower trading threshold
    %   l        : Stop-loss level (in standard deviation units)
    %   c_bar    : Normalized transaction cost (expected_C/SIGMA)
    %   f        : Position sizing fraction (0 < f <= 1)
    %
    % Outputs:
    %   X_OS      : Normalized spread process (X_OS = (Rt_OS - eta_hat)/SIGMA)
    %   value     : Theoretical expected annual return
    %   ann_return: Actual simulated annualized return

    % === 1. Normalize the Spread Process ===
    % Convert raw spread to OU process units (standard deviations from mean)
    X_OS = (Rt_OS - eta_hat) / SIGMA;

    % === 2. Calculate Strategy Metrics ===
    % Probability of hitting d_star before l (from u_star)
    erfid = @(x, y) erfi(x./sqrt(2)) - erfi(y./sqrt(2));
    p_pls = erfid(d_star, l)/erfid(u_star,l);
    
    % Maximum sustainable transaction cost
    c_max = p_pls*(u_star - l) - (d_star - l);

    % === 3. Evaluate Strategy Performance ===
    % Theoretical expected return (from model)
    value = evaluate_mu(d_star, u_star, c_bar, theta, l, SIGMA, f);
    
    % Simulated actual returns (via billionaire trading simulator)
    % Multiplied by 6 to annualize monthly returns (assuming 6-month period)
    ann_return = optimizedReturn(X_OS, d_star, u_star, l, c_bar, SIGMA, f, scaling_factor, w0, verbose_optimizedReturned);

    if verbose
        % === 4. Visualize Strategy ===
        figure;
        plot(X_OS, 'black', 'LineWidth', 1.2); hold on;
        
        % Plot trading thresholds
        yline(d_star, "green", 'LineWidth', 1.5, 'Label', 'd* (long entry)');
        yline(u_star, "blue", 'LineWidth', 1.5, 'Label', 'u* (short entry)');
        yline(l, "red", '--', 'LineWidth', 1.5, 'Label', 'Stop loss');
        
        % Format plot
        xlabel('Time (trading periods)', 'FontSize', 12);
        ylabel('Normalized Spread (X_{OS})', 'FontSize', 12);
        title('Pairs Trading Strategy Performance', 'FontSize', 14);
        legend({'Spread Process', 'd*', 'u*', 'Stop loss'}, 'Location', 'northeast');
        grid on;
    
        % === 5. Display Key Metrics ===
        fprintf('=== Strategy Performance Metrics ===\n');
        fprintf('Expected theoretical annual return: %.6f\n', value);
        fprintf('Actual normalized transaction cost: %.6fσ\n', c_bar);
        fprintf('Simulated annualized return: %.6f\n', ann_return);
        fprintf('Maximum sustainable cost: %.6fσ\n', c_max);
    end
end