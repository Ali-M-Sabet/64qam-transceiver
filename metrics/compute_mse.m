function mse = compute_mse(desired, estimated)
% Mean squared complex error.

    desired   = desired(:);
    estimated = estimated(:);

    assert(~isempty(desired) && numel(desired) == numel(estimated), ...
        'compute_mse:SizeMismatch', 'Symbol streams must be nonempty and equally sized.');

    mse = mean(abs(desired - estimated).^2);
end
