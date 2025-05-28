function proportion = computeTimeProportion(start_date, split, end_date)
    % COMPUTETIMEPROPORTION Calculate the proportional time between two periods
    %
    % Computes the fraction of time elapsed between start_date and split 
    % relative to the total period (start_date to end_date) using ACT/365 day count.
    %
    % Inputs:
    %   start_date - Initial date (datetime scalar)
    %   split      - Either: 
    %               1) Intermediate date (datetime) OR
    %               2) Duration from start_date (calendarDuration)
    %   end_date   - Final date (datetime scalar)
    %
    % Output:
    %   proportion - Time fraction (0-1), where:
    %               0 = split equals start_date
    %               1 = split equals end_date
    %
    % Example:
    %   p = computeTimeProportion(datetime('2023-01-01'), ...
    %                             calmonths(6), ...
    %                             datetime('2023-12-31')); % Returns ~0.5

    %% Input Validation
    % Check all inputs are valid datetime/duration objects
    if ~isdatetime(start_date) || ~isdatetime(end_date)
        error('Start and end dates must be datetime objects');
    end
    
    if ~(isdatetime(split) || isa(split, 'calendarDuration'))
        error('Split must be datetime or calendarDuration');
    end
    
    % Ensure single dates (not arrays)
    if ~isscalar(start_date) || ~isscalar(end_date) || ...
       (~isscalar(split) && ~isa(split, 'calendarDuration'))
        error('All inputs must be scalar');
    end
    
    %% Calculate Intermediate Date
    % Handle both datetime and duration inputs for split
    if isa(split, 'calendarDuration')
        split_date = start_date + split;
    else
        split_date = split;
        
        % Verify split is between start and end dates
        if split_date < start_date || split_date > end_date
            error('Split date must be between start and end dates');
        end
    end

    %% Compute Time Proportions
    % Using ACT/365 convention (yearfrac convention 3)
    partial_period = yearfrac(start_date, split_date, 3);  % start-to-split
    total_period = yearfrac(start_date, end_date, 3);      % start-to-end
    
    %% Final Calculation
    proportion = partial_period / total_period;
    
    % Clamp to [0,1] range to handle floating-point precision
    proportion = max(0, min(1, proportion));
end