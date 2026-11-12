function design = calculate_design(inputs)
%CALCULATE_DESIGN Derive the serial-link design in the required order.
%   The only circuit inputs are f, RL, L1, L2, Q1, and Q2. ZinTarget is a
%   design requirement rather than an additional measured circuit value.

arguments
    inputs (1,1) struct
end

requiredFields = ["f", "RL", "L1", "L2", "Q1", "Q2", "ZinTarget"];
for fieldName = requiredFields
    assert(isfield(inputs, fieldName), "Missing input field: %s", fieldName);
    validateattributes(inputs.(fieldName), {'double'}, ...
        {'real', 'finite', 'positive', 'scalar'}, mfilename, char(fieldName));
end

design = inputs;
design.omega = 2*pi*design.f;

% Step 1: unloaded Q gives the two winding resistances.
design.R1 = design.omega*design.L1/design.Q1;
design.R2 = design.omega*design.L2/design.Q2;

% Step 2: impose RL as the efficiency-maximising load, then derive k and M.
assert(design.RL > design.R2, "RL must exceed R2 for a real coupling solution.");
design.M = sqrt((design.RL^2 - design.R2^2)*design.R1/design.R2)/design.omega;
design.k = design.M/sqrt(design.L1*design.L2);
assert(design.k > 0 && design.k < 1, "The derived coupling coefficient is outside (0, 1).");

% Step 3: derive L and C for a real input impedance equal to ZinTarget.
design.reflectedResistance = (design.omega*design.M)^2/(design.R2 + design.RL);
design.branchResistance = design.R1 + design.reflectedResistance;
design.L = sqrt(design.ZinTarget*design.branchResistance)/design.omega;
design.C = 1/(design.omega^2*design.L);

% C1 and C2 are supporting LCC-C tuning values, not additional search variables.
assert(design.L < design.L1, "The derived L must be smaller than L1 to obtain a positive C1.");
design.C1 = 1/(design.omega^2*(design.L1 - design.L));
design.C2 = 1/(design.omega^2*design.L2);

% This value should reproduce RL and is kept as an explicit audit check.
design.optimumLoadCheck = sqrt(design.R2^2 + ...
    (design.omega*design.M)^2*design.R2/design.R1);
end
