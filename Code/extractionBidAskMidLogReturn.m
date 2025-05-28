function [Rt, timestamp, bid_A, bid_B, ask_A, ask_B, mid_A, mid_B] = extractionBidAskMidLogReturn(T, column_timestamp, columnBidA, columnBidB, columnAskA, columnAskB, converterA, converterB)
    % EXTRACTIONBIDASKMIDLOGRETURN Processes market data for pairs trading analysis
    %
    % Extracts and processes bid/ask data for two correlated instruments to:
    % 1. Filter valid data points
    % 2. Convert prices to common units
    % 3. Calculate mid-prices
    % 4. Compute log price ratio (spread)
    %
    % Inputs:
    %   T               - Input table containing raw market data
    %   column_timestamp- Column index/name for timestamps
    %   columnBidA      - Column index/name for Instrument A bid prices
    %   columnBidB      - Column index/name for Instrument B bid prices
    %   columnAskA      - Column index/name for Instrument A ask prices
    %   columnAskB      - Column index/name for Instrument B ask prices
    %   converterA      - Conversion factor for Instrument A (e.g., to USD/barrel)
    %   converterB      - Conversion factor for Instrument B (e.g., to USD/barrel)
    %
    % Outputs:
    %   Rt          - Log price ratio (spread): log(mid_A/mid_B)
    %   timestamp   - Filtered timestamps of valid observations
    %   bid_A       - Converted bid prices for Instrument A
    %   bid_B       - Converted bid prices for Instrument B
    %   ask_A       - Converted ask prices for Instrument A
    %   ask_B       - Converted ask prices for Instrument B
    %   mid_A       - Mid prices for Instrument A: (bid_A + ask_A)/2
    %   mid_B       - Mid prices for Instrument B: (bid_B + ask_B)/2

    %% Data Extraction Phase
    % Extract raw price data from input table columns
    timestamp = T{:, column_timestamp};  % Market timestamps
    bid_A = T{:, columnBidA};            % Raw bid prices - Instrument A
    bid_B = T{:, columnBidB};            % Raw bid prices - Instrument B
    ask_A = T{:, columnAskA};            % Raw ask prices - Instrument A
    ask_B = T{:, columnAskB};            % Raw ask prices - Instrument B
    
    %% Data Validation
    % Identify complete observations (no missing values in any price column)
    % This ensures all price points have both bid and ask data for both instruments
    valid_idx = ~isnan(bid_A) & ~isnan(ask_A) & ~isnan(bid_B) & ~isnan(ask_B);
    
    % Apply filter to all data vectors
    timestamp = timestamp(valid_idx);    % Filtered timestamps
    
    %% Price Conversion
    % Convert prices to standardized units using conversion factors
    % (e.g., converting different contract sizes to common units)
    bid_A = bid_A(valid_idx) * converterA;  % Normalized Instrument A bids
    ask_A = ask_A(valid_idx) * converterA;  % Normalized Instrument A asks
    bid_B = bid_B(valid_idx) * converterB;  % Normalized Instrument B bids
    ask_B = ask_B(valid_idx) * converterB;  % Normalized Instrument B asks
    
    %% Mid-Price Calculation
    % Compute mid-point between bid and ask prices
    % Represents fair market value for each instrument
    mid_A = (bid_A + ask_A) / 2;  % Instrument A mid-price
    mid_B = (bid_B + ask_B) / 2;  % Instrument B mid-price

    %% Spread Calculation
    % Compute log price ratio (standard metric for pairs trading)
    % Rt = log(Price_A / Price_B) forms the mean-reverting spread series
    Rt = log(mid_A ./ mid_B);
end