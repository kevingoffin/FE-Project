function mu_vec = evaluate_mu(d_vec, u_vec, c_vec, theta_vec, l_vec, SIGMA_vec, f_vec)
    % EVALUATE_MU Vectorized evaluation of expected annualized return (μ)
    %
    % Computes mu(i) = μ(d_vec(i), u_vec(i), c_vec(i), theta_vec(i), l_vec(i), SIGMA_vec(i), f_vec(i))
    %
    % Inputs:
    %   d_vec      : Vector of lower thresholds (N×1)
    %   u_vec      : Vector of upper thresholds (N×1)
    %   c_vec      : Vector of normalized transaction costs (N×1)
    %   theta_vec  : Vector of mean-reversion timescales (N×1)
    %   l_vec      : Vector of stop-loss levels (N×1)
    %   SIGMA_vec  : Vector of stationary volatilities (N×1)
    %   f_vec      : Vector of leverage values (N×1)
    %
    % Output:
    %   mu_vec     : Vector of expected annualized returns (N×1)

    % Ensure all inputs are column vectors
    d_vec = d_vec(:);
    u_vec = u_vec(:);
    c_vec = c_vec(:);
    theta_vec = theta_vec(:);
    l_vec = l_vec(:);
    SIGMA_vec = SIGMA_vec(:);
    f_vec = f_vec(:);

    % Compute effective deltas
    delta_up = u_vec - d_vec - c_vec;
    delta_low = l_vec - d_vec - c_vec;

    % Denominators of OU transition probabilities
    denom_up = erfid(u_vec, d_vec);
    denom_low = erfid(d_vec, l_vec);

    % Expected log-returns from each leg
    prof_up = log(1 + f_vec .* (exp(SIGMA_vec .* delta_up) - 1));
    prof_low = log(1 + f_vec .* (exp(SIGMA_vec .* delta_low) - 1));

    % Combine both paths to compute long-run average return
    mu_vec = (2 ./ (pi .* theta_vec)) .* (prof_up ./ denom_up + prof_low ./ denom_low);
end
