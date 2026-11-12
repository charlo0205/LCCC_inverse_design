function y = lccc_evaluate(p)
% One frequency-domain Simulink evaluation. p=[k L C C1 C2 R f].
set_param('LCCC_phasor/Parameters','Value',mat2str(p,17));
out=sim('LCCC_phasor','StopTime','0','ReturnWorkspaceOutputs','on');
raw=out.get('phasor_result');
if isstruct(raw), y=raw.signals.values(end,:); else, y=raw(end,:); end
if numel(y)~=11 || any(~isfinite(y)), error('Invalid phasor simulation result'); end
end
