function [Rt_IS, Rt_OS, time_IS, time_OS] = cleaner(Rt, timestamp, n, Input_Format, threshold_AntipersistentOutliers, verbose)
    % CLEANER Filters dataset by splitting into In-Sample/Out-of-Sample periods and removing outliers
    % Inputs:
    %   Rt        - Return time series vector
    %   timestamp - Corresponding datetime strings
    %   n         - Number of months for In-Sample period
    %   Input_Format - Input format of the datetime vector timestamp
    %   threshold_AntipersistentOutliers - threshold of the line 60
    %   verbose - if set to true, displays the number of removed outliers
    % Outputs:
    %   [Rt_IS, Rt_OS] - Filtered return series
    %   [time_IS, time_OS] - Corresponding filtered timestamps

    % Convert and sort timestamps
    timestamp = datetime(timestamp, 'InputFormat', Input_Format);
    [~, idx] = sort(timestamp); % Sort chronologically (if not already sorted)
    timestamp = timestamp(idx);
    Rt = Rt(idx);
    
    % Prepare the split dataset into In-Sample (IS) and Out-of-Sample (OS) periods
    start_date = timestamp(1);
    split_date = start_date + n;  % n is the IS period
    if verbose
        % Save the original timestamp
        timestamp_orginal = timestamp;
    end

    % Copy the original Rt % Calculate IQR thresholds
    IQR = iqr(Rt);
    
    % Define the bounds
    lower_bound = quantile(Rt, 0.25) - 3 * IQR;
    upper_bound = quantile(Rt, 0.75) + 3 * IQR;
    
    % Remove the outliers
    mask = (lower_bound > Rt) | (Rt > upper_bound);
    timestamp(mask) = [];

    % Display the removed outliers
    if verbose
        % Get the index of the splitting
        idx = (timestamp == split_date);
        idx_split_date = find(idx, 1, 'first'); % Returns first occurrence
        idx_outliersfree = (timestamp == split_date);
        idx_split_date_outliersfree = find(idx_outliersfree, 1, 'first'); % Returns first occurrence

        % Displays results
        fprintf('Extreme outliers IS: %d found\n', size(timestamp_orginal(1:idx_split_date-1),1) - size(timestamp(1:idx_split_date_outliersfree-1),1));
        fprintf('Extreme outliers OS: %d found\n', size(timestamp_orginal(idx_split_date:end),1) - size(timestamp(idx_split_date_outliersfree:end),1));

        % Save the original timestamp
        timestamp_orginal = timestamp;
    end

    % Compute differences for outlier detection
    diff_prev = abs(Rt(2:end-1) - Rt(1:end-2));
    diff_next = abs(Rt(3:end) - Rt(2:end-1));
    
    % Create a logical mask for outliers (same size as Rt_without_extreme_outliers)
    is_outlier = false(size(Rt));
    is_outlier(2:end-1) = (diff_prev > IQR) & (diff_next >= threshold_AntipersistentOutliers * IQR);
    
    % Remove outliers directly using logical indexing
    timestamp = timestamp(~is_outlier);

    % Create logical indices for period separation
    IS_idx = timestamp < split_date;
    OS_idx = timestamp >= split_date;

    % Display the removed outliers
    if verbose
        % Displays results
        fprintf('Extreme outliers IS: %d found\n', size(timestamp_orginal(1:idx_split_date_outliersfree-1),1) - size(timestamp(IS_idx),1));
        fprintf('Extreme outliers OS: %d found\n', size(timestamp_orginal(idx_split_date_outliersfree:end),1) - size(timestamp(OS_idx),1));
    end
    
    % Allocate the values
    Rt_IS = Rt(IS_idx);
    Rt_OS = Rt(OS_idx);
    time_IS = timestamp(IS_idx);
    time_OS = timestamp(OS_idx);
end