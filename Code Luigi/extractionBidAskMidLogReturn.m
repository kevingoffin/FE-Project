function [Rt, timestamp, mid_A, mid_B, bid_A, bid_B, ask_A, ask_B] = ...
    extractionBidAskMidLogReturn(T, column_timestamp, columnA, columnB, converterA, converterB, flag)
    % EXTRACTIONBIDASKMIDLOGRETURN Processes raw market data for statistical arbitrage
    %
    % This function extracts, filters, and processes bid/ask market data from two instruments,
    % and computes the log price ratio (spread) used for pairs trading.
    %
    % Inputs:
    %   T               - Table of raw market data (e.g., from Excel or CSV)
    %   column_timestamp- Index or name of the timestamp column
    %   columnA         - Two-element vector of column indices/names for Instrument A [bid, ask]
    %   columnB         - Two-element vector of column indices/names for Instrument B [bid, ask]
    %   converterA      - Unit conversion factor for Instrument A (e.g., $/gallon to $/barrel)
    %   converterB      - Unit conversion factor for Instrument B
    %   flag            - Logical switch to determine processing mode:
    %                       true  = use bid/ask to compute mid-prices
    %                       false = use direct mid-price columns
    %
    % Outputs:
    %   Rt        - Log price spread: log(mid_A / mid_B)
    %   timestamp - Timestamps of valid observations
    %   mid_A     - Mid prices for Instrument A
    %   mid_B     - Mid prices for Instrument B
    %   bid_A     - Converted bid prices for Instrument A (empty if flag=false)
    %   bid_B     - Converted bid prices for Instrument B (empty if flag=false)
    %   ask_A     - Converted ask prices for Instrument A (empty if flag=false)
    %   ask_B     - Converted ask prices for Instrument B (empty if flag=false)

    %% Case 1: Use bid and ask data to compute mid-prices
    if flag
        % Extract columns from the table
        timestamp = T{:, column_timestamp};   % Extract timestamps
        bid_A     = T{:, columnA(1)};         % Raw bid prices for Instrument A
        ask_A     = T{:, columnA(2)};         % Raw ask prices for Instrument A
        bid_B     = T{:, columnB(1)};         % Raw bid prices for Instrument B
        ask_B     = T{:, columnB(2)};         % Raw ask prices for Instrument B

        % Filter rows with complete data (no NaNs)
        valid_idx = ~isnan(bid_A) & ~isnan(ask_A) & ~isnan(bid_B) & ~isnan(ask_B);
        timestamp = timestamp(valid_idx);     % Filter timestamps

        % Apply unit conversion to valid entries
        bid_A = bid_A(valid_idx) * converterA;
        ask_A = ask_A(valid_idx) * converterA;
        bid_B = bid_B(valid_idx) * converterB;
        ask_B = ask_B(valid_idx) * converterB;

        % Compute mid-prices
        mid_A = (bid_A + ask_A) / 2;
        mid_B = (bid_B + ask_B) / 2;

    %% Case 2: Use directly provided mid-prices (simplified input)
    else
        timestamp = T{:, column_timestamp};   % Extract timestamps
        mid_A     = T{:, columnA} * converterA;
        mid_B     = T{:, columnB} * converterB;
        bid_A     = [];   % Leave bid/ask arrays empty
        ask_A     = [];
        bid_B     = [];
        ask_B     = [];
    end

    %% Compute log-price spread
    % The spread Rt is the log ratio between normalized mid-prices
    Rt = log(mid_A ./ mid_B);
end
