function [C_max, p_pls, p_mns] = maximum_transaction_cost(d_star, u_star, l)
    % MAXIMUM_TRANSACTION_COST Computes the maximum sustainable transaction cost (C_max)
    % and crossing probabilities for a pairs trading strategy with given thresholds.
    %
    % Inputs:
    %   d_star : Optimal lower trading threshold (long entry when spread < d_star)
    %   u_star : Optimal upper trading threshold (short entry when spread > u_star)
    %   l      : Stop-loss level (absolute value)
    %
    % Outputs:
    %   C_max : Maximum transaction cost that keeps strategy profitable
    %   p_pls : Probability of spread crossing d_star before l (from u_star)
    %   p_mns : Probability of spread crossing u_star before l (from d_star)
    %
    % Methodology:
    %   Uses the imaginary error function (erfi) to compute probabilities in an
    %   Ornstein-Uhlenbeck process. Derived from stochastic process theory.

    % === 1. Define helper function for erfi differences ===
    % erfid(x,y) = erfi(x/√2) - erfi(y/√2)
    % This computes the probability-weighted distance between thresholds
    erfid = @(x, y) erfi(x./sqrt(2)) - erfi(y./sqrt(2));

    % === 2. Compute crossing probabilities ===
    % p_pls: Probability spread hits d_star before l (starting from u_star)
    %        Represents chance of successful mean-reversion after short entry
    p_pls = erfid(d_star, l) / erfid(u_star, l);

    % p_mns: Probability spread hits u_star before l (starting from d_star)
    %        Represents chance of successful mean-reversion after long entry
    p_mns = erfid(u_star, d_star) / erfid(u_star, l);

    % === 3. Calculate maximum sustainable cost ===
    % C_max = p_pls*(u_star - l) - (d_star - l)
    % This is the expected profit from short trades minus expected loss from long trades,
    % representing the maximum cost that maintains non-negative expected returns
    C_max = p_pls*(u_star - l) - (d_star - l);
end