function [Rt_IS, time_IS, Rt_OS, time_OS] = IS_OS_split(Rt, timeStamp, splitTime, verbose)
% IS_OS_SPLIT Splits a time series into in-sample and out-of-sample segments.
%
% This function divides financial time series data into:
%   - In-sample period (used for model calibration/training)
%   - Out-of-sample period (used for validation/testing)
%
% Inputs:
%   Rt        - Vector of log-spread or price spread values
%   timeStamp - Corresponding datetime array
%   splitTime - Either:
%                • a calendarDuration (e.g., calmonths(9)) relative to the first date
%                • a datetime specifying an absolute split point
%   verbose   - Logical flag; if true, displays partition summary
%
% Outputs:
%   Rt_IS     - In-sample spread values
%   time_IS   - In-sample timestamps
%   Rt_OS     - Out-of-sample spread values
%   time_OS   - Out-of-sample timestamps

    %% Input Validation
    if ~isdatetime(timeStamp)
        error('Input "timeStamp" must be a datetime array.');
    end

    if ~(isa(splitTime, 'calendarDuration') || isdatetime(splitTime))
        error('Input "splitTime" must be a calendarDuration or a datetime object.');
    end

    %% Determine Split Date
    startDate = timeStamp(1);
    if isa(splitTime, 'calendarDuration')
        splitDate = startDate + splitTime;
    else
        splitDate = splitTime;
    end

    %% Partition Data
    IS_mask = timeStamp < splitDate;
    OS_mask = timeStamp >= splitDate;

    Rt_IS = Rt(IS_mask);
    time_IS = timeStamp(IS_mask);

    Rt_OS = Rt(OS_mask);
    time_OS = timeStamp(OS_mask);

    %% Warnings for Empty Sets
    if isempty(Rt_IS)
        warning('In-Sample period is empty. Check "splitTime".');
    end
    if isempty(Rt_OS)
        warning('Out-of-Sample period is empty. Check "splitTime".');
    end

    %% Optional Verbose Output
    if verbose
        fprintf('Time series split at %s\n', datetime(splitDate));
        if ~isempty(Rt_IS)
            fprintf(' - In-Sample:      %s to %s  (%d observations)\n', ...
                datetime(time_IS(1)), datetime(time_IS(end)), numel(Rt_IS));
        end
        if ~isempty(Rt_OS)
            fprintf(' - Out-of-Sample:  %s to %s  (%d observations)\n', ...
                datetime(time_OS(1)), datetime(time_OS(end)), numel(Rt_OS));
        end
    end
end