function val = interp_erfi(x, grid_x, grid_val, sqrt2)
    % INTERP_ERFI Computes scaled and interpolated imaginary error function values
    %
    % Efficiently approximates erfi(x/√2) using precomputed values and linear
    % interpolation, with clamping to handle out-of-range inputs.
    %
    % Inputs:
    %   x       - Input value(s) at which to evaluate erfi(x/√2)
    %   grid_x  - Predefined x-grid points for interpolation lookup table
    %   grid_val- Precomputed erfi values corresponding to grid_x
    %   sqrt2   - Precomputed √2 constant for efficiency
    %
    % Output:
    %   val     - Interpolated erfi values, clamped to 0 for out-of-range inputs
    %
    % Note: Uses linear interpolation for speed and clamps to 0 when x/√2 is outside
    %       the predefined grid range (extrapolation value = 0)

    % Scale input by 1/√2 to match erfi lookup table scaling
    x_scaled = x / sqrt2;
    
    % Perform linear interpolation with clamping (extrapolation returns 0)
    val = interp1(grid_x, grid_val, x_scaled, 'linear', 0);
end