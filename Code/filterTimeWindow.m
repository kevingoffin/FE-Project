function [filteredTable] = filterTimeWindow(timestamps, spreadValues, startHour, endHour, includeFlag, verbose)
    % FILTERTIMEWINDOW Filters time series data based on specified time window
    %
    % Filters financial time series data to either include or exclude a specific 
    % time window each day (e.g., regular trading hours). Handles both datetime 
    % and duration inputs.
    %
    % Inputs:
    %   timestamps    - Array of datetime or duration values
    %   spreadValues  - Corresponding price spread values
    %   startHour     - Start of time window (hours, e.g., 9.5 for 9:30 AM)
    %   endHour       - End of time window (hours, e.g., 16 for 4:00 PM)
    %   includeFlag   - Logical flag:
    %                   true = keep only data within [startHour, endHour]
    %                   false = exclude data within [startHour, endHour]
    %   verbose       - Logical flag to display filtering statistics
    %
    % Output:
    %   filteredTable - Table containing filtered timestamps and spread values
    %                   with metadata about the filtering operation

    %% Input Validation
    validateattributes(timestamps, {'datetime', 'duration'}, {'vector'});
    validateattributes(spreadValues, {'numeric'}, {'vector', 'numel', numel(timestamps)});
    validateattributes(startHour, {'numeric'}, {'scalar', '>=', 0, '<=', 24});
    validateattributes(endHour, {'numeric'}, {'scalar', '>=', 0, '<=', 24});
    
    %% Convert to time-of-day if datetimes are provided
    if isdatetime(timestamps)
        timeOfDay = timeofday(timestamps);
    else
        timeOfDay = timestamps; % Assume already in timeofday format
    end
    
    %% Create filtering mask
    startTime = hours(startHour);
    endTime = hours(endHour);
    
    if includeFlag
        % Include only data within the specified window
        keepMask = (timeOfDay >= startTime) & (timeOfDay <= endTime);
        action = 'Including';
    else
        % Exclude data within the specified window
        keepMask = (timeOfDay < startTime) | (timeOfDay > endTime);
        action = 'Excluding';
    end
    
    %% Apply filtering
    filteredTimestamps = timestamps(keepMask);
    filteredSpreads = spreadValues(keepMask);
    
    %% Create output table with metadata
    filteredTable = table(filteredTimestamps, filteredSpreads, ...
        'VariableNames', {'Timestamp', 'Spread'});
    
    % Store filtering parameters as metadata
    filteredTable.Properties.Description = sprintf(...
        'Filtered data | %s %.1f-%.1f | Kept %d of %d points (%.1f%%)', ...
        action, startHour, endHour, ...
        sum(keepMask), numel(keepMask), 100*mean(keepMask));
    
    %% Display filtering statistics if requested
    if verbose
        fprintf('\nTime Window Filtering Results:\n');
        fprintf('Action: %s %.1f-%.1f\n', action, startHour, endHour);
        fprintf('Original points: %d\n', numel(timestamps));
        fprintf('Filtered points: %d (%.1f%%)\n', ...
            sum(keepMask), 100*mean(keepMask));
        
        if isdatetime(timestamps)
            fprintf('Date range: %s to %s\n', ...
                datetime(min(filteredTimestamps)), ...
                datetime(max(filteredTimestamps)));
        end
    end
end