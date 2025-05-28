function [Rt_IS_NY_Filtered, Rt_OS_NY_Filtered] = filterTimeWindow(time_IS_NY, time_OS_NY, Rt_IS_filtered, Rt_OS_filtered, start_time, end_time, flag, verbose)
    % FILTER_NY Filters time series data based on New York trading hours
    %
    % Filters price spread data to either include or exclude specific trading hours
    % (e.g., regular NY trading hours 9:30-16:00)
    %
    % Inputs:
    %   time_IS_NY       - In-sample timestamps (datetime array)
    %   time_OS_NY       - Out-of-sample timestamps (datetime array)
    %   Rt_IS_filtered   - Filtered in-sample price spread series
    %   Rt_OS_filtered   - Filtered out-of-sample price spread series
    %   start_time       - Start hour for filtering (e.g., 9.5 for 9:30 AM)
    %   end_time         - End hour for filtering (e.g., 16 for 4:00 PM)
    %   flag             - Boolean control:
    %                     true = keep only data within [start_time, end_time]
    %                     false = exclude data within [start_time, end_time]
    %
    % Outputs:
    %   Rt_IS_NY_Filtered - Table with filtered in-sample data (timestamp, spread)
    %   Rt_OS_NY_Filtered - Table with filtered out-of-sample data (timestamp, spread)

    %% Extract time-of-day components
    % Convert datetimes to time durations since midnight
    T_IS_tod = timeofday(time_IS_NY);  % In-sample times of day
    T_OS_tod = timeofday(time_OS_NY);  % Out-of-sample times of day

    %% Apply time filters based on flag
    if flag
        % Keep only data within specified trading hours
        keep_IS = (T_IS_tod >= hours(start_time)) & (T_IS_tod <= hours(end_time));
        keep_OS = (T_OS_tod >= hours(start_time)) & (T_OS_tod <= hours(end_time));
        
        if verbose
            fprintf('Keeping %.2f-%.2f NY time: IS %d/%d (%.1f%%), OS %d/%d (%.1f%%)\n', ...
                start_time, end_time, ...
                sum(keep_IS), length(keep_IS), 100*mean(keep_IS), ...
                sum(keep_OS), length(keep_OS), 100*mean(keep_OS));
        end
    else
        % Exclude data within specified trading hours (keep overnight/after-hours)
        keep_IS = (T_IS_tod < hours(start_time)) | (T_IS_tod > hours(end_time));
        keep_OS = (T_OS_tod < hours(start_time)) | (T_OS_tod > hours(end_time));
        
        if verbose
            fprintf('Excluding %.2f-%.2f NY time: IS %d/%d (%.1f%%), OS %d/%d (%.1f%%)\n', ...
                start_time, end_time, ...
                sum(keep_IS), length(keep_IS), 100*mean(keep_IS), ...
                sum(keep_OS), length(keep_OS), 100*mean(keep_OS));
        end
    end

    %% Create filtered output tables
    Rt_IS_NY_Filtered = table(time_IS_NY(keep_IS), Rt_IS_filtered(keep_IS), ...
        'VariableNames', {'Timestamp_NY', 'Rt_IS'});
    
    Rt_OS_NY_Filtered = table(time_OS_NY(keep_OS), Rt_OS_filtered(keep_OS), ...
        'VariableNames', {'Timestamp_NY', 'Rt_OS'});

    %% Add metadata to tables
    Rt_IS_NY_Filtered.Properties.Description = sprintf('Filtered IS data (flag=%d, %.1f-%.1f NY)', flag, start_time, end_time);
    Rt_OS_NY_Filtered.Properties.Description = sprintf('Filtered OS data (flag=%d, %.1f-%.1f NY)', flag, start_time, end_time);
end