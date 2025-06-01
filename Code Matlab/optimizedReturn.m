function rtn = optimizedReturn(X_OS, d_star_vec, u_star_vec, l, c, SIGMA, f_vec, scaling_factor, w0, verbose)
    % OPTIMIZEDRETURN Computes strategy returns for multiple threshold and leverage configurations
    %
    % Inputs:
    %   X_OS          : Out-of-sample spread process (log price ratio), vector of prices
    %   d_star_vec    : Vector of lower trading thresholds (long entry when X_OS < d_star)
    %   u_star_vec    : Vector of upper trading thresholds (short entry when X_OS > u_star)
    %   l             : Stop-loss threshold (absolute value, scalar)
    %   c             : Transaction cost (scalar, per trade)
    %   SIGMA         : Volatility of the spread process (scalar)
    %   f_vec         : Vector of leverage levels (position sizing fractions)
    %   scaling_factor: Scalar to scale final log return
    %   w0            : Initial wealth
    %   verbose       : Verbose flag for displaying trade messages
    %
    % Output:
    %   rtn           : Vector of final scaled log-returns for each configuration

    % === 0. Initialize ===
    N = length(d_star_vec);         % Number of configurations
    T = length(X_OS);               % Time series length
    rtn = zeros(N, 1);              % Output return vector

    % === 1. Loop Over Each Strategy Configuration ===
    for j = 1:N
        d_star = d_star_vec(j);
        u_star = u_star_vec(j);
        f = f_vec(j);
        wlt = w0;                     % Wealth tracker for this config

        % Trading flags for long/short positions
        flag_long = false;
        flag_short = false;

        % Compute payoffs for long and short positions
        v_pls_L = exp(SIGMA * (u_star - d_star - 2 * c)) - 1;       % Profit on long exit
        v_mns_L = exp(SIGMA * (l - d_star - 2 * c)) - 1;            % Loss on long stop-loss
        v_pls_S = exp(SIGMA * (-u_star + d_star - 2 * c)) - 1;      % Profit on short exit
        v_mns_S = exp(SIGMA * (-l + d_star - 2 * c)) - 1;           % Loss on short stop-loss

        % === 2. Walk Through the Time Series ===
        for i = 2:T
            % --- Long Entry: Cross below d_star from above ---
            if X_OS(i) >= d_star && ~flag_long && X_OS(i-1) < d_star && X_OS(i-1) > l
                flag_long = true;

            % --- Short Entry: Cross above -d_star from below ---
            elseif X_OS(i) <= -d_star && ~flag_short && X_OS(i-1) > -d_star && X_OS(i-1) < -l
                flag_short = true;
            end

            % --- Long Exit Conditions ---
            if X_OS(i) >= u_star && flag_long && X_OS(i-1) < u_star
                wlt = wlt * (1 + f * v_pls_L);
                if verbose
                    fprintf('Closed long (j=%d) at profit\n', j);
                end
                flag_long = false;

            elseif X_OS(i) <= l && flag_long
                wlt = wlt * (1 + f * v_mns_L);
                flag_long = false;
            end

            % --- Short Exit Conditions ---
            if X_OS(i) <= -u_star && flag_short && X_OS(i-1) > -u_star
                wlt = wlt * (1 + f * v_mns_S);
                if verbose
                    fprintf('Closed short (j=%d) at profit\n', j);
                end
                flag_short = false;

            elseif X_OS(i) >= -l && flag_short
                wlt = wlt * (1 + f * v_pls_S);
                flag_short = false;
            end
        end

        % === 3. Store Final Return for This Configuration ===
        rtn(j) = scaling_factor * log(wlt / w0);
    end
end
