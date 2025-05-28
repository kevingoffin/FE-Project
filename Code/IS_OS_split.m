function [Rt_IS, time_IS, Rt_OS, time_OS] = IS_OS_split(Rt, timeStamp, splitTime, verbose)
    % IS_OS_SPLIT Partitions time series data into In-Sample and Out-of-sample periods
    %
    % Divides financial time series data into two distinct periods for:
    % - Model training/calibration (In-Sample)
    % - Strategy validation (Out-of-Sample)
    %
    % Inputs:
    %   Rt        - Price spread series (log ratio or raw values)
    %   timeStamp - Corresponding datetime array
    %   splitTime - Duration object (e.g., calmonths(9)) or datetime specifying split point
    %   verbose   - If true we show the results
    %
    % Outputs:
    %   Rt_IS    - In-Sample price spread series
    %   time_IS  - Corresponding In-Sample timestamps
    %   Rt_OS    - Out-of-Sample price spread series
    %   time_OS  - Corresponding Out-of-Sample timestamps

    %% Validate Inputs
    % Ensure timeStamp is datetime array
    if ~isdatetime(timeStamp)
        error('timeStamp must be a datetime array');
    end
    
    % Check splitTime type (accepts duration or datetime)
    if ~isa(splitTime, 'calendarDuration') && ~isdatetime(splitTime)
        error('splitTime must be duration (e.g., calmonths(9)) or datetime');
    end

    %% Temporal Partitioning
    % Determine split point
    start_date = timeStamp(1);  % First observation timestamp
    if isa(splitTime, 'calendarDuration')
        split_date = start_date + splitTime;  % Relative split (e.g., 9 months after start)
    else
        split_date = splitTime;  % Absolute datetime split
    end

    %% Create Period Masks
    % In-Sample (training period - typically 70-80% of data)
    IS_idx = timeStamp < split_date;
    
    % Out-of-Sample (testing period - remaining 20-30% of data)
    OS_idx = timeStamp >= split_date;

    %% Data Extraction
    % Verify non-empty partitions
    if ~any(IS_idx)
        warning('Empty In-Sample period - check splitTime');
    end
    if ~any(OS_idx)
        warning('Empty Out-of-Sample period - check splitTime');
    end

    % Extract partitioned data
    Rt_IS = Rt(IS_idx);      % In-Sample spread values
    time_IS = timeStamp(IS_idx); % Corresponding timestamps
    Rt_OS = Rt(OS_idx);      % Out-of-Sample spread values
    time_OS = timeStamp(OS_idx); % Corresponding timestamps

    %% Diagnostic Reporting
    if verbose
        fprintf('Data partitioned:\n');
        fprintf(' - In-Sample:  %s to %s (%d observations)\n', datetime(time_IS(1)), datetime(time_IS(end)), length(Rt_IS));
        fprintf(' - Out-of-Sample: %s to %s (%d observations)\n', datetime(time_OS(1)), datetime(time_OS(end)), length(Rt_OS));
    end
end