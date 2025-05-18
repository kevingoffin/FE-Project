function [Rt_IS_NY_Filtered, Rt_OS_NY_Filtered] = filter_time_window(time_IS_NY, time_OS_NY, Rt_IS_filtered, Rt_OS_filtered, start_time, end_time, flag)
% FILTER_NY keeps only the values with a time between start_time and end_time.
%
% Inputs:
%   time_IS_NY      - Datetime array (New York timezone) for IS (in-sample) data
%   time_OS_NY      - Datetime array (New York timezone) for OS (out-of-sample) data
%   Rt_IS_filtered  - Filtered Rt values corresponding to time_IS_NY
%   Rt_OS_filtered  - Filtered Rt values corresponding to time_OS_NY
%   start_time      - Start hour for filtering (numeric, e.g., 9 for 9 AM)
%   end_time        - End hour for filtering (numeric, e.g., 17 for 5 PM)
%   flag            - Binary flag to determine inclusion (true) or exclusion (false) of time window
%
% Outputs:
%   Rt_IS_NY_Filtered - Table with filtered IS timestamps and Rt values
%   Rt_OS_NY_Filtered - Table with filtered OS timestamps and Rt values

    if flag
        % --- CASE 1: KEEP DATA INSIDE [start_time, end_time] WINDOW ---
        
        % Extract time-of-day (without date) for IS data
        T_IS_tod = timeofday(time_IS_NY);
        keep_IS = (T_IS_tod >= hours(start_time)) & (T_IS_tod <= hours(end_time));  % Logical mask: True if time is between start_time and end_time
 
        % Repeat for OS data
        T_OS_tod = timeofday(time_OS_NY);
        keep_OS = (T_OS_tod >= hours(start_time)) & (T_OS_tod <= hours(end_time)); 

        % Create output tables with filtered data
        Rt_IS_NY_Filtered = table(time_IS_NY(keep_IS), Rt_IS_filtered(keep_IS), ...
                'VariableNames', {'Timestamp_NY', 'Rt_IS'});
        Rt_OS_NY_Filtered = table(time_OS_NY(keep_OS), Rt_OS_filtered(keep_OS), ...
                'VariableNames', {'Timestamp_NY', 'Rt_OS'});

    else
        % --- CASE 2: KEEP DATA OUTSIDE [start_time, end_time] WINDOW ---
        
        % Extract time-of-day for IS data
        T_IS_tod = timeofday(time_IS_NY);     
        % Logical mask: True if time is BEFORE start_time OR AFTER end_time
        keep_IS = (T_IS_tod <= hours(start_time)) | (T_IS_tod >= hours(end_time));            
        
        % Repeat for OS data
        T_OS_tod = timeofday(time_OS_NY);
        keep_OS = (T_OS_tod <= hours(start_time)) | (T_OS_tod >= hours(end_time));   

        % Create output tables with filtered data
        Rt_IS_NY_Filtered = table(time_IS_NY(keep_IS), Rt_IS_filtered(keep_IS), ...
                'VariableNames', {'Timestamp_NY', 'Rt_IS'});
        Rt_OS_NY_Filtered = table(time_OS_NY(keep_OS), Rt_OS_filtered(keep_OS), ...
                'VariableNames', {'Timestamp_NY', 'Rt_OS'});
    end
end