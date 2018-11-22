function [A] = assemble_stiffness_elementlist(mu, fespace, elementlist )
% Assemble poisson matrix with boundary conditions
% input=
%           fespace: finite elemnet space
%           fun: anonymous function of the forcing term
%           mu: anonymous function or scalar of the diffusion coefficient
%               If scalar, the code is optimized on structured meshes
%           dirichlet_functions: Dirichlet boundary data
%           neumann_functions: Neumann_boundary data
%           elementlist: array containing the elements
% output=
%           A: system matrix

constant_mu = 0;

if (~isa(mu,'function_handle'))
    constant_mu = 1;
end

connectivity = fespace.connectivity;
vertices = fespace.mesh.vertices;
nodes = fespace.nodes;

n_elements = size(connectivity,1);
n_nodes = size(nodes,1);
n_functions = fespace.n_functions_per_element;
n_functionsqr = n_functions^2;

% number of gauss points
n_gauss = 3;

elements_A = zeros(n_functions*n_elements,1);
indices_i = zeros(n_functions*n_elements,1);
indices_j = zeros(n_functions*n_elements,1);

display(num2str(n_functions*n_elements))

if (~strcmp(fespace.mesh.type,'structured'))
    
    display('entering the if-!structured if')
    
    [gp,weights,~] = gauss_points2D(n_gauss);
    if (~constant_mu)
        for i = elementlist(:)'
            indices = connectivity(i,1:end-1);
            x1 = vertices(indices(1),1:2)';
            x2 = vertices(indices(2),1:2)';
            x3 = vertices(indices(3),1:2)';
            
            [I1,I2] = meshgrid(indices,indices);
            
            currindices = (i-1)*n_functionsqr+1:n_functionsqr*i;
            indices_i(currindices) = I1(:);
            indices_j(currindices) = I2(:);
            
            new_elements = zeros(size(I1,1)^2,1);
            
            mattransf = [x2-x1 x3-x1];
            invmat = inv(mattransf);
            
            % transformation from parametric to physical
            transf = @(x) mattransf*x + x1;
            dettransf = abs(det(mattransf));
            
            for j = 1:n_gauss
                transfgrad = invmat' * fespace.grads(gp(:,j));
                stiffness_elements = mu(transf(gp(:,j))) * dettransf*(transfgrad'*transfgrad) * weights(j) / 2;
                new_elements = new_elements + stiffness_elements(:);
            end
            elements_A(currindices) = new_elements;
        end
    else
        for i = elementlist(:)'
            indices = connectivity(i,1:end-1);
            x1 = vertices(indices(1),1:2)';
            x2 = vertices(indices(2),1:2)';
            x3 = vertices(indices(3),1:2)';
            
            [I1,I2] = meshgrid(indices,indices);
            
            currindices = (i-1)*n_functionsqr+1:n_functionsqr*i;
            indices_i(currindices) = I1(:);
            indices_j(currindices) = I2(:);
            
            new_elements = zeros(size(I1,1)^2,1);
            
            mattransf = [x2-x1 x3-x1];
            invmat = inv(mattransf);
            
            % transformation from parametric to physical
            dettransf = abs(det(mattransf));
            
            for j = 1:n_gauss
                transfgrad = invmat' * fespace.grads(gp(:,j));
                stiffness_elements = mu*dettransf*(transfgrad'*transfgrad)*weights(j)/2;
                new_elements = new_elements + stiffness_elements(:);
            end
            elements_A(currindices) = new_elements;
        end
    end
else
    
    display('entering the if-structured if !!')

    [fespace,gp] = add_members_structured_meshes(fespace, n_gauss);
    if (~constant_mu)
        for i = elementlist(:)'
            indices = connectivity(i,1:end-1);
            x1 = vertices(indices(1),1:2)';
            
            [I1,I2] = meshgrid(indices,indices);
            currindices = (i-1)*n_functionsqr+1:n_functionsqr*i;
            indices_i(currindices) = I1(:);
            indices_j(currindices) = I2(:);
            
            new_elements = zeros(size(I1,1)^2,1);
            
            % then the triangle is in this configuration /|
            if (indices(2) == indices(1) + 1)
                for j = 1:n_gauss
                    stiffness_elements = mu(fespace.transf1(gp(:,j),x1))* ...
                        fespace.stiffness_elements1{j};
                    new_elements = new_elements + stiffness_elements(:);
                end
            else
                for j = 1:n_gauss
                    stiffness_elements = mu(fespace.transf2(gp(:,j),x1))* ...
                        fespace.stiffness_elements2{j};
                    new_elements = new_elements + stiffness_elements(:);
                end
            end
            elements_A(currindices) = new_elements;
        end
    else
        for i = elementlist(:)'
            indices = connectivity(i,1:end-1);
            
            [I1,I2] = meshgrid(indices,indices);
            currindices = (i-1)*n_functionsqr+1:n_functionsqr*i;
            indices_i(currindices) = I1(:);
            indices_j(currindices) = I2(:);
            
            % then the triangle is in this configuration /|
            if (indices(2) == indices(1) + 1)
                new_elements = fespace.stiffness_elements_sum1;
            else
                new_elements = fespace.stiffness_elements_sum2;
            end
            elements_A(currindices) = new_elements;
        end
        elements_A = elements_A*mu;
    end
end
no_indices = (indices_i == 0);
indices_i(no_indices) = [];
indices_j(no_indices) = [];
elements_A(no_indices) = [];

size(indices_i)
size(indices_j)
size(elements_A)
length(elements_A(elements_A ~= 0))

A = sparse(indices_i,indices_j,elements_A,n_nodes,n_nodes);

