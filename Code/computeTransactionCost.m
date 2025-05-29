function [C, expected_C, SIGMA, c_bar, theta] = computeTransactionCost( ...
    bid_HO, bid_LGO, ask_HO, ask_LGO, timeStamp, ...
    sigma_hat, k_hat, startHour, endHour, splitTime, index_outliers)
    % COMPUTETRANSACTIONCOST Calculates transaction costs and related metrics for a pairs trading strategy.
    %
    % Inputs:
    %   bid_HO, bid_LGO       - Bid prices for HO (Heating Oil) and LGO (Low Gas Oil)
    %   ask_HO, ask_LGO       - Ask prices for HO and LGO
    %   timeStamp             - Timestamps for price observations
    %   sigma_hat             - Estimated volatility of the spread
    %   k_hat                 - Estimated mean-reversion rate of the spread
    %   startHour, endHour    - Trading window (e.g., 9:30–16:00)
    %   splitTime             - Time to split data into in-sample (IS) and out-of-sample (OS)
    %   index_outliers        - Logical mask where true = keep, false = outlier
    %
    % Outputs:
    %   C          - Vector of round-trip transaction costs
    %   expected_C - Mean transaction cost (liquidity proxy)
    %   SIGMA      - Stationary volatility of the OU process
    %   c_bar      - Normalized transaction cost (cost relative to volatility)
    %   theta      - Mean-reversion time scale (1/k_hat)

    % === 1. Outlier Removal ===
    % Remove data points flagged as outliers in all price series and timestamps
    % Note: 'index_outliers' is a logical mask where false indicates outliers
    bid_HO(~index_outliers) = [];
    bid_LGO(~index_outliers) = [];
    ask_HO(~index_outliers) = [];
    ask_LGO(~index_outliers) = [];
    timeStamp(~index_outliers) = [];

    % === 2. Train-Test Split (In-Sample/Out-of-Sample) ===
    % Split each cleaned series into in-sample (IS) and out-of-sample (OS) portions
    % Only the IS data (before splitTime) is retained for analysis
    [bid_HO_IS, timeStamp_IS, ~, ~] = IS_OS_split(bid_HO, timeStamp, splitTime, false);
    [bid_LGO_IS, ~, ~, ~] = IS_OS_split(bid_LGO, timeStamp, splitTime, false);
    [ask_HO_IS, ~, ~, ~] = IS_OS_split(ask_HO, timeStamp, splitTime, false);
    [ask_LGO_IS, ~, ~, ~] = IS_OS_split(ask_LGO, timeStamp, splitTime, false);

    % === 3. Filter by Trading Hours ===
    % Restrict data to observations within specified trading hours (e.g., 9:30–16:00)
    % Converts arrays to tables with timestamps and prices
    bid_HO_IS_Table = filterTimeWindow(timeStamp_IS, bid_HO_IS, startHour, endHour, true, false);
    bid_LGO_IS_Table = filterTimeWindow(timeStamp_IS, bid_LGO_IS, startHour, endHour, true, false);
    ask_HO_IS_Table = filterTimeWindow(timeStamp_IS, ask_HO_IS, startHour, endHour, true, false);
    ask_LGO_IS_Table = filterTimeWindow(timeStamp_IS, ask_LGO_IS, startHour, endHour, true, false);

    % === 4. Convert Tables to Arrays ===
    % Extract numeric price data from tables (discarding timestamps)
    bid_HO_IS_array = table2array(bid_HO_IS_Table(:, 2));  % Column 2 = prices
    bid_LGO_IS_array = table2array(bid_LGO_IS_Table(:, 2));
    ask_HO_IS_array = table2array(ask_HO_IS_Table(:, 2));
    ask_LGO_IS_array = table2array(ask_LGO_IS_Table(:, 2));

    % === 5. Compute Transaction Cost ===
    % Calculate round-trip cost for the pairs trading strategy:
    %   1. Buy HO at ask price, sell HO at bid price
    %   2. Buy LGO at ask price, sell LGO at bid price
    % The log ratio captures the percentage cost of the round-trip trade
    C = log(ask_HO_IS_array ./ bid_HO_IS_array) + log(ask_LGO_IS_array ./ bid_LGO_IS_array);

    % === 6. Normalize Transaction Cost ===
    expected_C = mean(C);                   % Average cost across all observations
    SIGMA = sigma_hat / sqrt(2 * k_hat);    % Stationary volatility of the Ornstein-Uhlenbeck process
    c_bar = expected_C / SIGMA;             % Cost-to-volatility ratio (trading signal strength)
    theta = 1 / k_hat;                      % Mean-reversion timescale (theta = 1/k_hat)
end