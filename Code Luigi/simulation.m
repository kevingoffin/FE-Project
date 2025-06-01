function [sigma_hat_i, k_hat_i, eta_hat_i] = simulation(Rt_0, n_sim, deltaT, eta_hat, k_hat, sigma_hat)
    % SIMULATION_BIS Performs Monte Carlo simulation and re-estimation of OU process parameters
    %
    % This function:
    % 1. Simulates multiple paths of an Ornstein-Uhlenbeck process using calibrated parameters
    % 2. Re-estimates parameters from each simulated path
    % 3. Returns distributions of parameter estimates for uncertainty analysis
    %
    % Inputs:
    %   Rt_0     - Original observed time series (for initial condition)
    %   n_sim    - Number of Monte Carlo simulations
    %   deltaT   - Time step between observations (in years)
    %   eta_hat  - Estimated long-term mean
    %   k_hat    - Estimated mean-reversion rate
    %   sigma_hat - Estimated volatility
    %
    % Outputs:
    %   sigma_hat_i - Distribution of re-estimated volatilities
    %   k_hat_i     - Distribution of re-estimated mean-reversion rates
    %   eta_hat_i   - Distribution of re-estimated long-term means

    %% 1. Simulation Parameters Setup
    T = length(Rt_0);           % Number of time steps (matches input data length)
    
    % OU process discretization parameters
    alpha = exp(-k_hat*deltaT); % Decay factor: e^{-κΔt}
    beta = 1 - alpha;           % Mean-reversion strength: 1 - e^{-κΔt}
    
    % Noise standard deviation (theoretical for exact discretization)
    sd = sigma_hat * sqrt((1 - alpha^2)/(2*k_hat));  

    %% 2. Monte Carlo Path Generation
    % Initialize matrix (rows = time, columns = simulations)
    X = zeros(T, n_sim);
    X(1,:) = Rt_0(1);  % All paths start from same initial value
    
    % Generate correlated Brownian motions
    rng(42);  % Set seed for reproducibility
    
    % Vectorized path simulation
    for j = 1:n_sim
        for t = 2:T
            % OU process update equation:
            % X_t = X_{t-1}*α + η(1-α) + σ√((1-α²)/2κ) * ε_t
            X(t,j) = X(t-1,j)*alpha ...  % Mean-reverting component
                   + eta_hat*beta ...    % Long-term mean pull
                   + sd*randn;           % Random innovation
        end
    end

    %% 3. Parameter Re-estimation
    % Preallocate results
    eta_hat_i = zeros(1, n_sim);
    k_hat_i = zeros(1, n_sim);
    zeta_hat_i = zeros(1, n_sim);  % Residual variances
    inv_T = 1 / (T - 1);           % Precompute reciprocal
    
    % Parallel loop over simulations
    parfor j = 1:n_sim
        x = X(:, j);
        x_prev = x(1:end-1);  % X_t
        x_next = x(2:end);    % X_{t+1}
        
        % Compute moments with numerical safeguards
        mu_prev = mean(x_prev);
        mu_next = mean(x_next);
        var_prev = max(mean(x_prev.^2) - mu_prev^2, eps);  % Avoid zero variance
        covar = mean(x_prev .* x_next) - mu_prev * mu_next;
        
        % Estimate κ (mean-reversion rate)
        % Using autocorrelation: κ = -ln(ρ)/Δt where ρ = cov(X_t,X_{t+1})/var(X_t)
        ratio = max(covar / var_prev, eps);  % Clamp to (0,1]
        k_hat_i(j) = -(1 / deltaT) * log(ratio);
        
        % Estimate η (long-term mean)
        % Using moment matching: η ≈ E[X_{t+1}] + (X_T-X_1)/T * ρ/(1-ρ)
        eta_hat_i(j) = mu_next + (x(end) - x(1)) * inv_T * (ratio / (1 - ratio + eps));
        
        % Estimate residual variance (ζ)
        zeta_hat_i(j) = max(var(x_next) - (covar^2 / var_prev), 0);
    end

    %% 4. Volatility Recovery
    % Transform residual variance to OU volatility (σ)
    % Using exact relation: ζ = σ²(1-e^{-2κΔt})/(2κ)
    denom = max(1 - exp(-2 * k_hat_i * deltaT), eps);  % Avoid division by zero
    sigma_hat_i = sqrt((2 * k_hat_i .* zeta_hat_i) ./ denom);
    
    % Note: For small κΔt, this simplifies to σ ≈ √(ζ/Δt)
end