function filteredTable = filterTimeWindow(timestamps, spreadValues, startHour, endHour, includeFlag, verbose)
% FILTERTIMEWINDOW Filters time series data based on daily time-of-day window.
%
% This function allows you to include or exclude specific daily time windows
% (e.g., regular trading hours) from a financial time series. It supports both 
% datetime and duration formats for timestamps.
%
% Inputs:
%   timestamps   - Array of datetime or duration values
%   spreadValues - Numeric vector of corresponding spread values
%   startHour    - Start of time window (in hours, e.g., 9.5 for 9:30 AM)
%   endHour      - End of time window (in hours, e.g., 16 for 4:00 PM)
%   includeFlag  - Logical flag:
%                    true  => retain data inside the window
%                    false => exclude data inside the window
%   verbose      - Logical flag; if true, displays filtering statistics
%
% Output:
%   filteredTable - Table with filtered timestamps and spread values.
%                   Includes filtering description in metadata.

    %% Input Validation
    validateattributes(timestamps, {'datetime', 'duration'}, {'vector'});
    validateattributes(spreadValues, {'numeric'}, {'vector', 'numel', numel(timestamps)});
    validateattributes(startHour, {'numeric'}, {'scalar', '>=', 0, '<=', 24});
    validateattributes(endHour, {'numeric'}, {'scalar', '>=', 0, '<=', 24});

    %% Convert timestamps to time-of-day
    if isdatetime(timestamps)
        timeOfDay = timeofday(timestamps);
    else
        timeOfDay = timestamps; % Already duration-type input
    end

    %% Define time window
    windowStart = hours(startHour);
    windowEnd = hours(endHour);

    %% Build inclusion/exclusion mask
    if includeFlag
        mask = (timeOfDay >= windowStart) & (timeOfDay <= windowEnd);
        operation = 'Included';
    else
        mask = (timeOfDay < windowStart) | (timeOfDay > windowEnd);
        operation = 'Excluded';
    end

    %% Filter the data
    filteredTimestamps = timestamps(mask);
    filteredSpreads = spreadValues(mask);

    %% Construct output table with metadata
    filteredTable = table(filteredTimestamps, filteredSpreads, ...
        'VariableNames', {'Timestamp', 'Spread'});

    percentKept = 100 * mean(mask);
    filteredTable.Properties.Description = sprintf( ...
        '%s time window: %.1f–%.1f hrs | Retained %d of %d (%.1f%%)', ...
        operation, startHour, endHour, sum(mask), numel(mask), percentKept);

    %% Optional verbose reporting
    if verbose
        fprintf('\nTime Window Filtering Summary:\n');
        fprintf('Operation       : %s [%.1f - %.1f hrs]\n', operation, startHour, endHour);
        fprintf('Original points : %d\n', numel(timestamps));
        fprintf('Points retained : %d (%.1f%%)\n', sum(mask), percentKept);
        if isdatetime(timestamps) && ~isempty(filteredTimestamps)
            fprintf('Date range      : %s to %s\n', ...
                datetime(min(filteredTimestamps)), datetime(max(filteredTimestamps)));
        end
    end
end
