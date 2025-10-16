function indperm = nk_VisXPermHelper(act, N, nperms, L)

s = RandStream.create('mt19937ar','seed',sum(100*clock));
RandStream.setGlobalStream(s);

switch act
    case 'genpermlabel'
        indperm = zeros(N, nperms);
        if exist('L','var') && ~isempty(L)
            uL = unique(L); nuL = numel(uL);
            if nuL<=20
                for perms = 1:nperms
                    vec = (1:N)';
                    for n = 1:nuL
                        Nn = length(vec);
                        idxl = L==uL(n);
                        idxn = randperm(Nn,sum(idxl));
                        indperm(idxl,perms) = vec(idxn);
                        vec(idxn) = [];
                    end
                end
            else
                for perms = 1:nperms
                    indperm(:,perms) = randperm(N); 
                end
            end
        else
            for perms = 1:nperms
                indperm(:,perms) = randperm(N); 
            end
        end
    case 'genpermfeats'
        uL = unique(L); nuL = numel(uL);
        indperm = zeros(nuL, N, nperms);
        for i = 1:nuL
            for perms = 1:nperms
                indperm(i,:,perms) = randperm(N);
            end
        end
    %% Hardcoded by ISP for the BOKI study
    % Individuals belonging to one dyad are always after one another, i.e.,
    % the indices of dyad 1 are 1 and 2 while the indices of dyad 24 are 47
    % and 48
    case 'genpermdyad'

        indperm = zeros(N, nperms);
        for perms = 1:nperms
            Lperm = randperm(N/2); % randomly choose the dyads
            indperm(:,perms) = [(Lperm*2)-1, Lperm*2]; % extend to subjects
        end

end





