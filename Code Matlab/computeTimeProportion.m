function proportion = computeTimeProportion(startDate, split, endDate)
% COMPUTETIMEPROPORTION Calculates the relative time fraction between two dates.
%
% This function computes the proportion of time between `startDate` and a `split`
% point relative to the full period from `startDate` to `endDate`. It supports 
% split points specified either as a datetime or as a calendar duration.
%
% Time is measured using the ACT/365 day count convention.
%
% Inputs:
%   startDate - Starting point of the period (datetime scalar)
%   split     - Intermediate point, either as:
%                 - datetime (absolute split date), or
%                 - calendarDuration (offset from startDate)
%   endDate   - End of the full period (datetime scalar)
%
% Output:
%   proportion - Fraction between 0 and 1 indicating progress from startDate to endDate.
%
% Examples:
%   computeTimeProportion(datetime(2023,1,1), calmonths(6), datetime(2023,12,31))
%   computeTimeProportion(datetime(2023,1,1), datetime(2023,9,1), datetime(2023,12,31))

    %% Input Validation
    validateattributes(startDate, {'datetime'}, {'scalar'});
    validateattributes(endDate, {'datetime'}, {'scalar'});

    if ~(isdatetime(split) || isa(split, 'calendarDuration'))
        error('Split must be a datetime or calendarDuration.');
    end

    %% Determine the Split Date
    if isa(split, 'calendarDuration')
        splitDate = startDate + split;
    else
        splitDate = split;
    end

    % Ensure splitDate is within bounds
    if splitDate < startDate || splitDate > endDate
        error('Split date must lie within the start and end dates.');
    end

    %% Compute Proportions Using ACT/365 Convention
    elapsed = yearfrac(startDate, splitDate, 3);   % 3 = ACT/365
    total   = yearfrac(startDate, endDate, 3);

    %% Return Clamped Proportion
    proportion = max(0, min(1, elapsed / total));
end