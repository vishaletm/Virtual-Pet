#define FLUVIO_SOLVER
#include "../../Includes/FluvioCompute.cginc"
#define SolverUtility_GetParticleArrayIndex(particleIndex, particleCount) ((particleIndex) >= (particleCount) ? (particleIndex) - (particleCount) : (particleIndex));
inline float Poly6Calculate(float4 dist, float poly6Factor, float kernelSizeSq){float lenSq = dot(dist, dist);float diffSq = kernelSizeSq - lenSq;return poly6Factor*diffSq*diffSq*diffSq;}inline float4 Poly6CalculateGradient(float4 dist, float poly6Factor, float kernelSizeSq){float lenSq = dot(dist, dist);float diffSq = kernelSizeSq - lenSq;float f = -poly6Factor*6.0f*diffSq*diffSq;return dist*f;}inline float Poly6CalculateLaplacian(float4 dist, float poly6Factor, float kernelSizeSq){float lenSq = dot(dist, dist);float diffSq = kernelSizeSq - lenSq;float f = lenSq - (0.75f*diffSq);return poly6Factor*24.0f*diffSq*diffSq*f;}inline float SpikyCalculate(float4 dist, float spikyFactor, float kernelSize){float lenSq = dot(dist, dist);float f = kernelSize - sqrt(lenSq);return spikyFactor*f*f*f;}inline float4 SpikyCalculateGradient(float4 dist, float spikyFactor, float kernelSize){float lenSq = dot(dist, dist);float len = sqrt(lenSq);float f = -spikyFactor*3.0f*(kernelSize - len)*(kernelSize - len)/len;return dist*f;}inline float ViscosityCalculate(float4 dist, float viscosityFactor, float kernelSize3, float kernelSizeSq, float kernelSize){float lenSq = dot(dist, dist);float len = sqrt(lenSq);float len3 = len*len*len;return viscosityFactor*(((-len3/(2.0f*kernelSize3)) + (lenSq/kernelSizeSq) + (kernelSize/(2.0f*len))) - 1.0f);}inline float4 ViscosityCalculateGradient(float4 dist, float viscosityFactor, float kernelSize3, float kernelSizeSq, float kernelSize){float lenSq = dot(dist, dist);float len = sqrt(lenSq);float len3 = len*len*len;float f = viscosityFactor*((-3.0f*len/(2.0f*kernelSize3)) + (2.0f/kernelSizeSq) + (kernelSize/(2.0f*len3)));return dist*f;}inline float ViscosityCalculateLaplacian(float4 dist, float viscosityFactor, float kernelSize3, float kernelSize){float lenSq = dot(dist, dist);float len = sqrt(lenSq);return viscosityFactor*(6.0f/kernelSize3)*(kernelSize - len);}inline int mod_pow2(int a, int b){return a & (b - 1);}inline int fluvio_IndexGrid_GetXIndex(float4 position, float cellSpace){int x = (int)(fabs(position.x) / cellSpace);return mod_pow2(x, FLUVIO_MAX_GRID_SIZE);}inline int fluvio_IndexGrid_GetYIndex(float4 position, float cellSpace){int y = (int)(fabs(position.y) / cellSpace);return mod_pow2(y, FLUVIO_MAX_GRID_SIZE);}inline int fluvio_IndexGrid_GetZIndex(float4 position, float cellSpace, int depth){int z = (int)(fabs(position.z) / cellSpace);return mod_pow2(z, depth);}inline int fluvio_IndexGrid_GetIndex(int x, int y, int z){return x + FLUVIO_MAX_GRID_SIZE * (y + FLUVIO_MAX_GRID_SIZE * z);}inline int fluvio_IndexGrid_GetIndexFromPosition(float4 position, float cellSpace, float depth){float x = fluvio_IndexGrid_GetXIndex(position, cellSpace);float y = fluvio_IndexGrid_GetYIndex(position, cellSpace);float z = fluvio_IndexGrid_GetZIndex(position, cellSpace, depth);return fluvio_IndexGrid_GetIndex(x, y, z);}inline void fluvio_IndexGrid_Add(FLUVIO_BUFFER_SOLVER_RW(int) grid, int particleIndex, float4 position, float kernelSize, float depth){float cellSpace = kernelSize / FLUVIO_GRID_BUCKET_SIZE;grid[fluvio_IndexGrid_GetIndexFromPosition(position, cellSpace, depth)] = particleIndex;}inline int fluvio_IndexGrid_Query(FLUVIO_BUFFER_SOLVER_RW(int) grid,int depth,int particleIndex,int particleCount,int stride,float kernelSize,float kernelSizeSq,FLUVIO_BUFFER_SOLVER_RW(FluidParticle) particle,FLUVIO_BUFFER_SOLVER_RW(FluidParticle) boundaryParticle,FLUVIO_BUFFER_SOLVER_RW(int) neighbors){int x, y, z;int xOff, yOff, zOff;int gridIndex, neighborIndex;float4 dist;float d;int particleInd = SolverUtility_GetParticleArrayIndex(particleIndex, particleCount);int neighborInd;int neighborCount = 0;float cellSpace = kernelSize / FLUVIO_GRID_BUCKET_SIZE;int gridLength = FLUVIO_MAX_GRID_SIZE * FLUVIO_MAX_GRID_SIZE * depth;float4 pos = particleInd == particleIndex ? particle[particleInd].position : boundaryParticle[particleInd].position;x = fluvio_IndexGrid_GetXIndex(pos, cellSpace);y = fluvio_IndexGrid_GetYIndex(pos, cellSpace);z = fluvio_IndexGrid_GetZIndex(pos, cellSpace, depth);int maxOff = FLUVIO_GRID_BUCKET_SIZE / 2;int minOff = -maxOff;for (int xOffset = minOff; xOffset <= maxOff; xOffset++){for (int yOffset = minOff; yOffset <= maxOff; yOffset++){for (int zOffset = minOff; zOffset <= maxOff; zOffset++){xOff = x + xOffset;yOff = y + yOffset;zOff = z + zOffset;gridIndex = fluvio_IndexGrid_GetIndex(xOff, yOff, zOff);if (gridIndex < 0 || gridIndex >= gridLength)continue;neighborIndex = grid[gridIndex];if (neighborIndex < 0 || particleIndex == neighborIndex) continue;neighborInd = SolverUtility_GetParticleArrayIndex(neighborIndex, particleCount);if (neighborInd == neighborIndex){dist = particle[neighborInd].position - pos;}else {dist = boundaryParticle[neighborInd].position - pos;}dist.w = 0;d = dot(dist, dist);if (d < kernelSizeSq){neighbors[particleIndex * stride + neighborCount++] = neighborIndex;if (neighborCount >= stride)return stride;}}}}return neighborCount;}inline int QueryIndexGrid(FLUVIO_BUFFER_SOLVER_RW(int) grid, int gridDepth, int particleIndex, int particleCount, int stride, float kernelSize, float kernelSizeSq, FLUVIO_BUFFER_SOLVER_RW(FluidParticle) particle, FLUVIO_BUFFER_SOLVER_RW(FluidParticle) boundaryParticle, FLUVIO_BUFFER_SOLVER_RW(int) neighbors){return fluvio_IndexGrid_Query(grid,gridDepth,particleIndex,particleCount,stride,kernelSize,kernelSizeSq,particle,boundaryParticle,neighbors);}inline int QueryBruteForce(int particleIndex, int particleCount, int boundaryParticleCount, int stride, float kernelSizeSq, FLUVIO_BUFFER_SOLVER_RW(FluidParticle) particle, FLUVIO_BUFFER_SOLVER_RW(FluidParticle) boundaryParticle, FLUVIO_BUFFER_SOLVER_RW(int) neighbors){int neighborCount = 0;float4 dist;float d;int particleInd = SolverUtility_GetParticleArrayIndex(particleIndex, particleCount);int neighborInd;int totalCount = particleCount + boundaryParticleCount;float4 particlePosition = particleInd == particleIndex ? particle[particleInd].position : boundaryParticle[particleInd].position;float4 neighborPosition;float neighborLifetime;for (int neighborIndex = 0; neighborIndex < totalCount; ++neighborIndex){neighborInd = SolverUtility_GetParticleArrayIndex(neighborIndex, particleCount);if (neighborInd == neighborIndex){neighborPosition = particle[neighborInd].position;neighborLifetime = particle[neighborInd].lifetime.x;}else {neighborPosition = boundaryParticle[neighborInd].position;neighborLifetime = boundaryParticle[neighborInd].lifetime.x;}dist = neighborPosition - particlePosition;dist.w = 0;d = dot(dist, dist);if (particleIndex != neighborIndex &&neighborLifetime > 0.0f &&d < kernelSizeSq){neighbors[particleIndex * stride + neighborCount++] = neighborIndex;if (neighborCount >= stride)return stride;}}return neighborCount;}FLUVIO_KERNEL_INDEX_GRID(Solver_IndexGridClear){
#ifdef FLUVIO_USE_INDEX_GRID_ON
int gridIndex = get_global_id(0);int gridLength = FLUVIO_MAX_GRID_SIZE * FLUVIO_MAX_GRID_SIZE * fluvio_IndexGridDepth;if (gridIndex >= gridLength) return;fluvio_IndexGrid[gridIndex] = -1;
#else 
fluvio_Particle[get_global_id(0)].force = 0;
#endif
}FLUVIO_KERNEL_INDEX_GRID(Solver_IndexGridAdd){
#ifdef FLUVIO_USE_INDEX_GRID_ON
int particleIndex = get_global_id(0);if (particleIndex >= fluvio_Count.y + fluvio_Count.w) return;int particleInd = SolverUtility_GetParticleArrayIndex(particleIndex, fluvio_Count.y);float lifetime;float4 position;if (particleIndex == particleInd){lifetime = fluvio_Particle[particleInd].lifetime.x;position = fluvio_Particle[particleInd].position;}else {lifetime = fluvio_IndexGridBoundaryParticle[particleInd].lifetime.x;position = fluvio_IndexGridBoundaryParticle[particleInd].position;}if (lifetime > 0.0f){fluvio_IndexGrid_Add(fluvio_IndexGrid, particleIndex, position, fluvio_KernelSize.x, fluvio_IndexGridDepth);}
#else 
fluvio_Particle[get_global_id(0)].force = 0;
#endif
}FLUVIO_KERNEL_INDEX_GRID(Solver_NeighborSearch){int particleIndex = get_global_id(0);if (particleIndex >= fluvio_Count.y + fluvio_Count.w) return;int particleInd = SolverUtility_GetParticleArrayIndex(particleIndex, fluvio_Count.y);float lifetime;int neighborCount = 0;if (particleIndex == particleInd){fluvio_Particle[particleInd].force = 0;lifetime = fluvio_Particle[particleInd].lifetime.x;}else {lifetime = fluvio_IndexGridBoundaryParticle[particleInd].lifetime.x;}if (lifetime > 0.0f){
#ifdef FLUVIO_USE_INDEX_GRID_ON
neighborCount = QueryIndexGrid(fluvio_IndexGrid,fluvio_IndexGridDepth,particleIndex,fluvio_Count.y,fluvio_Stride,fluvio_KernelSize.x,fluvio_KernelSize.y,fluvio_Particle,fluvio_IndexGridBoundaryParticle,fluvio_Neighbors);
#else 
neighborCount = QueryBruteForce(particleIndex,fluvio_Count.y,fluvio_Count.w,fluvio_Stride,fluvio_KernelSize.y,fluvio_Particle,fluvio_IndexGridBoundaryParticle,fluvio_Neighbors);
#endif
}if (particleIndex == particleInd){fluvio_Particle[particleInd].id.z = neighborCount;}else {fluvio_IndexGridBoundaryParticle[particleInd].id.z = neighborCount;}}FLUVIO_KERNEL(Solver_DensityPressure){int particleIndex = get_global_id(0);if (particleIndex >= fluvio_Count.y + fluvio_Count.w) return;int particleInd = SolverUtility_GetParticleArrayIndex(particleIndex, fluvio_Count.y);FluidData fluid;int neighborCount;float4 particlePosition;float particleLifetime;if (particleIndex == particleInd){fluid = fluvio_Fluid[fluvio_Particle[particleInd].id.x];neighborCount = fluvio_Particle[particleInd].id.z;particlePosition = fluvio_Particle[particleInd].position;particleLifetime = fluvio_Particle[particleInd].lifetime.x;}else {fluid = fluvio_Fluid[fluvio_BoundaryParticle[particleInd].id.x];neighborCount = fluvio_BoundaryParticle[particleInd].id.z;particlePosition = fluvio_BoundaryParticle[particleInd].position;particleLifetime = fluvio_BoundaryParticle[particleInd].lifetime.x;}int neighborIndex, neighborInd;float density = 0;float neighborMass;float4 dist;if (particleLifetime > 0.0f){for (int j = 0; j < neighborCount; ++j){neighborIndex = FluvioGetNeighborIndex(fluvio_Neighbors, particleIndex, fluvio_Stride, j);neighborInd = SolverUtility_GetParticleArrayIndex(neighborIndex, fluvio_Count.y);if (neighborIndex == neighborInd){neighborMass = fluvio_Fluid[fluvio_Particle[neighborInd].id.x].particleMass;dist = particlePosition - fluvio_Particle[neighborInd].position;}else {neighborMass = fluvio_Fluid[fluvio_BoundaryParticle[neighborInd].id.x].particleMass;dist = particlePosition - fluvio_BoundaryParticle[neighborInd].position;}dist.w = 0;density += neighborMass * Poly6Calculate(dist, fluvio_KernelFactors.x, fluvio_KernelSize.y);}if (particleIndex == particleInd){density = max(density, fluvio_Fluid[fluvio_Particle[particleInd].id.x].minimumDensity);fluvio_Particle[particleInd].density = density;fluvio_Particle[particleInd].pressure = fluvio_Fluid[fluvio_Particle[particleInd].id.x].gasConstant * (density - fluvio_Fluid[fluvio_Particle[particleInd].id.x].initialDensity);}else {density = max(density, fluvio_Fluid[fluvio_BoundaryParticle[particleInd].id.x].minimumDensity);fluvio_BoundaryParticle[particleInd].density = density;fluvio_BoundaryParticle[particleInd].pressure = fluvio_Fluid[fluvio_BoundaryParticle[particleInd].id.x].gasConstant * (density - fluvio_Fluid[fluvio_BoundaryParticle[particleInd].id.x].initialDensity);}}}FLUVIO_KERNEL(Solver_SurfaceTension){int particleIndex = get_global_id(0);if (particleIndex >= fluvio_Count.z) return;int neighborCount = fluvio_Particle[particleIndex].id.z;int neighborIndex;float neighborMass;float normalLen;float4 dist, normal = 0;if (fluvio_Particle[particleIndex].lifetime.x > 0.0f){for (int j = 0; j < neighborCount; ++j){neighborIndex = FluvioGetNeighborIndex(fluvio_Neighbors, particleIndex, fluvio_Stride, j);if (neighborIndex < fluvio_Count.z){neighborMass = fluvio_Fluid[fluvio_Particle[neighborIndex].id.x].particleMass;dist = fluvio_Particle[particleIndex].position - fluvio_Particle[neighborIndex].position;dist.w = 0;normal += (neighborMass / fluvio_Particle[neighborIndex].density) * Poly6CalculateGradient(dist, fluvio_KernelFactors.x, fluvio_KernelSize.y);}}normalLen = length(normal);fluvio_Particle[particleIndex].normal = normal / normalLen;fluvio_Particle[particleIndex].normal.w = normalLen;}}FLUVIO_KERNEL(Solver_Forces){int particleIndex = get_global_id(0);if (particleIndex >= fluvio_Count.z) return;int neighborCount = fluvio_Particle[particleIndex].id.z;int neighborIndex;float neighborMass, scalar;float4 dist, force;if (fluvio_Particle[particleIndex].lifetime.x > 0.0f){for (int j = 0; j < neighborCount; ++j){neighborIndex = FluvioGetNeighborIndex(fluvio_Neighbors, particleIndex, fluvio_Stride, j);if (neighborIndex < fluvio_Count.y){neighborMass = fluvio_Fluid[fluvio_Particle[neighborIndex].id.x].particleMass;dist = fluvio_Particle[particleIndex].position - fluvio_Particle[neighborIndex].position;dist.w = 0;scalar = neighborMass * (fluvio_Particle[particleIndex].pressure + fluvio_Particle[neighborIndex].pressure) / (fluvio_Particle[neighborIndex].density * 2.0f);force = SpikyCalculateGradient(dist, fluvio_KernelFactors.y, fluvio_KernelSize.x);force *= scalar;fluvio_Particle[particleIndex].force -= force;scalar = neighborMass * ViscosityCalculateLaplacian(dist, fluvio_KernelFactors.z, fluvio_KernelSize.z, fluvio_KernelSize.x) * (1.0f / fluvio_Particle[neighborIndex].density);force = (fluvio_Particle[neighborIndex].velocity - fluvio_Particle[particleIndex].velocity) / fluvio_KernelSize.w;force *= scalar * fluvio_Fluid[fluvio_Particle[particleIndex].id.x].viscosity;force.w = 0;fluvio_Particle[particleIndex].force += force;}}}}FLUVIO_KERNEL(Solver_BoundaryForces){int particleIndex = get_global_id(0);if (particleIndex >= fluvio_Count.z) return;int neighborCount = fluvio_Particle[particleIndex].id.z;int neighborIndex;float neighborMass, scalar;float4 dist, force;if (fluvio_Particle[particleIndex].lifetime.x > 0.0f){for (int j = 0; j < neighborCount; ++j){neighborIndex = FluvioGetNeighborIndex(fluvio_Neighbors, particleIndex, fluvio_Stride, j);if (neighborIndex >= fluvio_Count.y){neighborIndex -= fluvio_Count.y;neighborMass = fluvio_Fluid[fluvio_BoundaryParticle[neighborIndex].id.x].particleMass;dist = fluvio_Particle[particleIndex].position - fluvio_BoundaryParticle[neighborIndex].position;dist.w = 0;scalar = neighborMass * (fluvio_Particle[particleIndex].pressure + fluvio_BoundaryParticle[neighborIndex].pressure) / (fluvio_BoundaryParticle[neighborIndex].density * 2.0f);force = SpikyCalculateGradient(dist, fluvio_KernelFactors.y, fluvio_KernelSize.x);force *= scalar;fluvio_Particle[particleIndex].force -= force;scalar = neighborMass * ViscosityCalculateLaplacian(dist, fluvio_KernelFactors.z, fluvio_KernelSize.z, fluvio_KernelSize.x) * (1.0f / fluvio_BoundaryParticle[neighborIndex].density);force = (fluvio_BoundaryParticle[neighborIndex].velocity - fluvio_Particle[particleIndex].velocity) / fluvio_KernelSize.w;force *= scalar * fluvio_Fluid[fluvio_Particle[particleIndex].id.x].viscosity;force.w = 0;fluvio_Particle[particleIndex].force += force;}}}}FLUVIO_KERNEL(Solver_Turbulence){int particleIndex = get_global_id(0);if (particleIndex >= fluvio_Count.z) return;int neighborCount = fluvio_Particle[particleIndex].id.z;int neighborIndex;float neighborMass, neighborTurbulence, scalar;float4 dist, force;if (fluvio_Particle[particleIndex].lifetime.x > 0.0f){for (int j = 0; j < neighborCount; ++j){neighborIndex = FluvioGetNeighborIndex(fluvio_Neighbors, particleIndex, fluvio_Stride, j);if (neighborIndex < fluvio_Count.y){neighborMass = fluvio_Fluid[fluvio_Particle[neighborIndex].id.x].particleMass;neighborTurbulence = fluvio_Fluid[fluvio_Particle[neighborIndex].id.x].turbulence;dist = fluvio_Particle[particleIndex].position - fluvio_Particle[neighborIndex].position;dist.w = 0;if (neighborIndex < fluvio_Count.z && fluvio_Particle[particleIndex].vorticityTurbulence.w >= fluvio_Fluid[fluvio_Particle[particleIndex].id.x].turbulence && fluvio_Particle[neighborIndex].vorticityTurbulence.w < neighborTurbulence){scalar = neighborMass * ViscosityCalculateLaplacian(dist, fluvio_KernelFactors.z, fluvio_KernelSize.z, fluvio_KernelSize.x) * (1.0f / fluvio_Particle[neighborIndex].density);fluvio_Particle[particleIndex].vorticityTurbulence = scalar * (fluvio_Particle[neighborIndex].vorticityTurbulence - fluvio_Particle[particleIndex].vorticityTurbulence);force.xyz = clamp_len(FLUVIO_TURBULENCE_CONSTANT * cross(dist.xyz, fluvio_Particle[particleIndex].vorticityTurbulence.xyz), FLUVIO_MAX_SQR_VELOCITY_CHANGE * fluvio_Fluid[fluvio_Particle[particleIndex].id.x].particleMass);force.w = 0;fluvio_Particle[particleIndex].force += force;}}}}}FLUVIO_KERNEL(Solver_ExternalForces){int particleIndex = get_global_id(0);if (particleIndex >= fluvio_Count.z) return;int neighborCount = fluvio_Particle[particleIndex].id.z;int neighborIndex;float neighborMass, scalar;float4 dist, force;if (fluvio_Particle[particleIndex].lifetime.x > 0.0f){for (int j = 0; j < neighborCount; ++j){neighborIndex = FluvioGetNeighborIndex(fluvio_Neighbors, particleIndex, fluvio_Stride, j);if (neighborIndex < fluvio_Count.y){neighborMass = fluvio_Fluid[fluvio_Particle[neighborIndex].id.x].particleMass;dist = fluvio_Particle[particleIndex].position - fluvio_Particle[neighborIndex].position;dist.w = 0;if (fluvio_Particle[particleIndex].normal.w > FLUVIO_PI && fluvio_Particle[particleIndex].normal.w < FLUVIO_PI * 2.0f){scalar = neighborMass * Poly6CalculateLaplacian(dist, fluvio_KernelFactors.x, fluvio_KernelSize.y) * fluvio_Fluid[fluvio_Particle[particleIndex].id.x].surfaceTension * (1.0f / fluvio_Particle[neighborIndex].density);force = fluvio_Particle[particleIndex].normal;force.w = 0;force *= scalar;fluvio_Particle[particleIndex].force -= force;}}}fluvio_Particle[particleIndex].force += fluvio_Fluid[fluvio_Particle[particleIndex].id.x].gravity * (fluvio_Fluid[fluvio_Particle[particleIndex].id.x].buoyancyCoefficient * (fluvio_Particle[particleIndex].density - fluvio_Fluid[fluvio_Particle[particleIndex].id.x].initialDensity));}}FLUVIO_KERNEL(Solver_Constraints){int particleIndex = get_global_id(0);if (particleIndex >= fluvio_Count.z) return;float particleInvMass = 1.0f / fluvio_Fluid[fluvio_Particle[particleIndex].id.x].particleMass;float dt = fluvio_Time.y;int neighborCount = fluvio_Particle[particleIndex].id.z;float minDistance = (0.5f * fluvio_KernelSize.x);float minDistanceSq = minDistance * minDistance;int neighborIndex;float sqDistance, d;float4 dist;if (fluvio_Particle[particleIndex].lifetime.x > 0.0f){for (int j = 0; j < neighborCount; ++j){neighborIndex = FluvioGetNeighborIndex(fluvio_Neighbors, particleIndex, fluvio_Stride, j);if (neighborIndex < fluvio_Count.y){dist = fluvio_Particle[particleIndex].position - fluvio_Particle[neighborIndex].position;dist.w = 0;sqDistance = dot(dist, dist);if (sqDistance < minDistanceSq){if (sqDistance > FLUVIO_EPSILON){d = sqrt(sqDistance);dist *= (0.5f*(d - minDistance)/d);}else {dist.y = 0.5f * minDistance;}fluvio_Particle[particleIndex].force += (dist*particleInvMass)/dt;}}}}}