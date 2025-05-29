function w = erfi(x)
    % ERFI Computes the imaginary error function for real inputs.
    % 
    % The imaginary error function is defined as:
    %   erfi(x) = (2 / √π) ∫₀ˣ exp(t²) dt
    %
    % Inputs:
    %   x : Scalar or vector of real values
    %
    % Outputs:
    %   w : Vector of same size as x, where w(i) = erfi(x(i))

    % Ensure x is a column vector for consistent integration
    x = x(:);

    % Use arrayfun to compute the integral for each element
    w = arrayfun(@(xi) (2 / sqrt(pi)) * quadgk(@(t) exp(t.^2), 0, xi), x);

    % Reshape result to match input shape
    w = reshape(w, size(x));
end