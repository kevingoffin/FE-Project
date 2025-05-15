function w = erfi(x)
%ERFIC  Versione complessa di erfi basata su erfC
    w = zeros(length(x));
    for i=1:length(x)
        w(i) = (2/sqrt(pi))*quadgk(@(t) exp(t.^2), 0, x(i));
    end
end