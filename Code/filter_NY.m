function [Rt_IS_NY_Filtered, Rt_OS_NY_Filtered] = filter_NY(time_IS_NY, time_OS_NY, Rt_IS_filtered, Rt_OS_filtered, start_time, end_time, flag)

    if flag == 1
        T_IS_tod = timeofday(time_IS_NY);         
        keep_IS   = (T_IS_tod >= hours(start_time)) & (T_IS_tod <= hours(end_time));  

        T_OS_tod = timeofday(time_OS_NY);
        keep_OS = (T_OS_tod >= hours(start_time)) & (T_OS_tod <= hours(end_time)); 

        % 3) Crea le nuove serie filtrate con data e Rt
        Rt_IS_NY_Filtered = table(time_IS_NY(keep_IS), Rt_IS_filtered(keep_IS), ...
                'VariableNames', {'Timestamp_NY','Rt_IS'});
        Rt_OS_NY_Filtered = table(time_OS_NY(keep_OS), Rt_OS_filtered(keep_OS), ...
                'VariableNames', {'Timestamp_NY','Rt_OS'});
    else
        T_IS_tod = timeofday(time_IS_NY);     
        keep_IS   = (T_IS_tod < hours(start_time)) | (T_IS_tod > hours(end_time));            
        T_OS_tod = timeofday(time_OS_NY);
        keep_OS = (T_OS_tod < hours(start_time)) | (T_OS_tod > hours(end_time));   
        % 3) Crea le nuove serie filtrate con data e Rt
        Rt_IS_NY_Filtered = table(time_IS_NY(keep_IS), Rt_IS_filtered(keep_IS), ...
                'VariableNames', {'Timestamp_NY','Rt_IS'});
        Rt_OS_NY_Filtered = table(time_OS_NY(keep_OS), Rt_OS_filtered(keep_OS), ...
                'VariableNames', {'Timestamp_NY','Rt_OS'});
    end
end