function [d_vals, u_vals, d_star, u_star, c_bar, SIGMA, theta, expected_C] = optimizedTradingStrategy(midA, midB, sigma_hat, k_hat, l, f, c_vals, bidAskSpread)
    % PAIR_FUTURES Calculates optimal trading bands for a pairs trading strategy
    % between two futures contracts, accounting for transaction costs and mean-reversion dynamics.
    %
    % Inputs:
    %   midA, midB      : Mid prices for assets A and B (vectors)
    %   sigma_hat       : Estimated volatility of the price spread
    %   k_hat           : Estimated mean-reversion rate of the spread
    %   l               : Stop-loss level (in standard deviation units)
    %   f               : Position sizing fraction (0 < f <= 1)
    %   c_vals          : Vector of candidate normalized transaction costs
    %   bidAskSpread    : Average bid-ask spread (absolute price units)
    %
    % Outputs:
    %   d_vals, u_vals  : Vectors of optimal thresholds for all c_vals
    %   d_star, u_star  : Optimal thresholds for current market conditions
    %   c_bar           : Normalized transaction cost (expected_C/SIGMA)
    %   SIGMA           : Stationary volatility of the spread process
    %   theta           : Mean-reversion timescale (1/k_hat)
    %   expected_C      : Expected round-trip transaction cost

    % === 1. Calculate Bid/Ask Prices ===
    % Derive bid/ask prices from mid prices and spread
    half_bidAskSpread = bidAskSpread / 2;
    bid_A = midA - half_bidAskSpread;  % Bid price for asset A
    ask_A = midA + half_bidAskSpread;  % Ask price for asset A
    bid_B = midB - half_bidAskSpread;  % Bid price for asset B
    ask_B = midB + half_bidAskSpread;  % Ask price for asset B

    % === 2. Compute Transaction Costs ===
    % Calculate round-trip cost for the pairs strategy:
    % Cost = log(ask/bid) for Asset A + log(ask/bid) for Asset B
    C = log(ask_A./bid_A) + log(ask_B./bid_B);
    expected_C = mean(C);  % Average transaction cost

    % === 3. Spread Process Parameters ===
    SIGMA = sigma_hat/sqrt(2*k_hat);  % Stationary volatility of OU process
    theta = 1/k_hat;                 % Mean-reversion timescale

    % === 4. Optimal Trading Bands Calculation ===
    % Compute optimal (d,u) thresholds for all candidate cost values
    [d_vals, u_vals] = maximize_mu(c_vals, l, SIGMA, theta, f);

    % === 5. Select Bands for Current Market Conditions ===
    c_bar = expected_C/SIGMA;  % Normalized transaction cost
    [~, idx] = min(abs(c_vals - c_bar));  % Find closest c value in grid
    d_star = d_vals(idx);  % Optimal lower threshold
    u_star = u_vals(idx);  % Optimal upper threshold
end