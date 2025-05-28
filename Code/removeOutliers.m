function [Rt_filtered, time_filtered] = removeOutliers(Rt, timestamp, InputFormat, verbose)
    % REMOVEOUTLIERS Filters statistical and antipersistent outliers from price spread data
    %
    % Processes financial time series data to:
    % 1. Remove extreme statistical outliers (beyond 3*IQR)
    % 2. Filter antipersistent outliers (temporary price spikes that quickly revert)
    %
    % Inputs:
    %   Rt            - Log price ratio (spread) series
    %   timestamp     - Corresponding timestamps (string or datetime array)
    %   InputFormat   - Format string for datetime conversion (e.g., 'yyyy-MM-dd HH:mm:ss')
    %   verbose       - True means that we display the outliers removed
    %
    % Outputs:
    %   Rt_filtered   - Cleaned spread series with outliers removed
    %   time_filtered - Corresponding filtered timestamps

    %% Data Preparation
    % Convert string timestamps to datetime objects if needed
    if ischar(timestamp) || isstring(timestamp)
        timestamp = datetime(timestamp, 'InputFormat', InputFormat);
    end
    
    %% Phase 1: Statistical Outlier Removal
    % Calculate quartiles and interquartile range (IQR)
    Q1 = quantile(Rt, 0.25);  % 25th percentile (lower quartile)
    Q3 = quantile(Rt, 0.75);  % 75th percentile (upper quartile)
    IQR = Q3 - Q1;            % Interquartile range
    
    % Define outlier thresholds (3*IQR from quartiles)
    lower_bound = Q1 - 3 * IQR;  % Lower cutoff for extreme values
    upper_bound = Q3 + 3 * IQR;  % Upper cutoff for extreme values
    
    % Create logical mask for inlier values
    is_inlier = (Rt >= lower_bound) & (Rt <= upper_bound);
    
    % Apply statistical outlier filter
    Rt_filtered = Rt(is_inlier);
    time_filtered = timestamp(is_inlier);
    
    if verbose
        % Identify and store outliers before removal
        outlier_mask = ~is_inlier;
        outlier_values = Rt(outlier_mask);
        outlier_times = timestamp(outlier_mask);

        % Report number of statistical outliers removed
        num_stat_outliers = length(outlier_values);
        fprintf('Phase 1: Removed %d statistical outliers (|value| > 3*IQR)\n', num_stat_outliers);
        
        % Display detailed information about removed outliers if any exist
        if num_stat_outliers > 0
            fprintf('\nRemoved Outlier Details:\n');
            fprintf('%-25s %-15s %-10s\n', 'Timestamp', 'Value', 'Bound Violated');
            fprintf('%-25s %-15s %-10s\n', '---------', '-----', '---------------');
            
            for i = 1:num_stat_outliers
                if outlier_values(i) < lower_bound
                    bound_violated = sprintf('< %.4f (Lower)', lower_bound);
                else
                    bound_violated = sprintf('> %.4f (Upper)', upper_bound);
                end
                
                fprintf('%-25s %-15.4f %-10s\n', ...
                    datetime(outlier_times(i)), ...
                    outlier_values(i), ...
                    bound_violated);
            end
            fprintf('\n');
        else
            fprintf('No statistical outliers found.\n');
        end
    end
    
    %% Phase 2: Antipersistent Outlier Detection
    % Calculate price changes between consecutive points
    price_changes = diff(Rt_filtered);  % Rt(t) - Rt(t-1)
    
    % Identify antipersistent spikes (large changes that immediately reverse)
    is_spike = false(size(Rt_filtered));  % Initialize detection mask
    
    % Conditions for antipersistent outliers (applied to middle points only):
    % 1. Initial change exceeds IQR threshold
    % 2. Subsequent change recovers ≥95% of initial move
    % 3. Subsequent change is in opposite direction
    is_large_change = abs(price_changes(1:end-1)) > IQR;  % Condition 1
    is_recovered = abs(price_changes(2:end)) >= 0.95*abs(price_changes(1:end-1)); % Condition 2
    is_reversed = sign(price_changes(2:end)) == -sign(price_changes(1:end-1)); % Condition 3
    
    % Combine conditions for middle points (positions 2 to end-1)
    is_spike(2:end-1) = is_large_change & is_recovered & is_reversed;

    % Identify and store antipersistent outliers before removal
    if verbose
        spike_values = Rt_filtered(is_spike);
        spike_times = time_filtered(is_spike);
        spike_indices = find(is_spike);  % Get original indices
    end
    
    % Remove detected antipersistent outliers
    Rt_filtered = Rt_filtered(~is_spike);
    time_filtered = time_filtered(~is_spike);
    
    if verbose
        % Report number of antipersistent outliers removed
        num_anti_outliers = sum(is_spike);
        fprintf('Phase 2: Removed %d antipersistent outliers\n', num_anti_outliers);
        
        % Display detailed information about removed spikes if any exist
        if num_anti_outliers > 0
            fprintf('Removed Antipersistent Outlier Details:\n');
            fprintf('%-8s %-25s %-15s %-30s\n', 'Index', 'Timestamp', 'Value', 'Pattern');
            fprintf('%-8s %-25s %-15s %-30s\n', '-----', '---------', '-----', '-------');
            
            for i = 1:num_anti_outliers
                idx = spike_indices(i);
                % Describe the spike pattern (t-1 → t → t+1)
                pattern = sprintf('%.4f → %.4f → %.4f', ...
                    Rt_filtered(idx-1), ...
                    spike_values(i), ...
                    Rt_filtered(idx));
                
                fprintf('%-8d %-25s %-15.4f %-30s\n', ...
                    idx, ...
                    datetime(spike_times(i)), ...
                    spike_values(i), ...
                    pattern);
            end
            fprintf('\n');
        else
            fprintf('No antipersistent outliers found.\n');
        end
    end
end