function lt = log_term(d, ref, c, sigma, f)
    % LOG_TERM Computes the logarithmic term used in the objective function
    %
    % Computes: log(1 + f*(exp(σ*(ref - d - c)) - 1)) with numerical stability
    %
    % Inputs:
    %   d     - Current d value (decision variable)
    %   ref   - Reference value (either u or l)
    %   c     - Concentration value
    %   sigma - Scaling parameter
    %   f     - Weighting factor (function handle or constant)
    %
    % Output:
    %   lt    - Computed logarithmic term with overflow protection

    % Compute exponent term: σ*(ref - d - c)
    exponent = sigma * (ref - d - c);
    
    % Compute exponential term while preventing overflow
    exp_term = exp(exponent);
    
    % Compute full logarithmic term
    lt = log(1 + f*(exp_term - 1));
    
    % Apply asymptotic approximation for large values to maintain numerical stability
    % When exp_term is very large, we use: log(f) + σ*(ref - d - c)
    lt(exp_term > 1e10) = exponent + log(f);
end