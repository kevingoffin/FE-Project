function val = erfid(x, y)
% ERFID Computes the difference of imaginary error functions:
%       erfi(x / sqrt(2)) - erfi(y / sqrt(2))
%
%   val = ERFID(x, y)
%
%   Inputs:
%       x, y : Scalars, vectors, or matrices (must be compatible sizes)
%
%   Output:
%       val  : The same size as the broadcasted x and y inputs
%
%   Example:
%       x = [-1, 0, 1]; y = [0, 0, 0];
%       d = erfid(x, y);

    % Scale inputs
    x_scaled = x ./ sqrt(2);
    y_scaled = y ./ sqrt(2);

    % Ensure inputs are compatible
    if ~isequal(size(x_scaled), size(y_scaled))
        try
            % Try implicit expansion (MATLAB R2016b or newer)
            val = erfi(x_scaled) - erfi(y_scaled);
        catch
            error('Inputs x and y must be the same size or broadcast-compatible.');
        end
    else
        % Elementwise subtraction
        val = erfi(x_scaled) - erfi(y_scaled);
    end
end
