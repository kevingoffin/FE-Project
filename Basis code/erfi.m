function w = erfi(x)
    w = (2/sqrt(pi))*quadgk(@(t) exp(t.^2), 0, x);
end