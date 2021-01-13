### A Pluto.jl notebook ###
# v0.12.18

using Markdown
using InteractiveUtils

# ╔═╡ 391c0030-4f23-11eb-118d-7d4a50bbe3aa
begin
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.add(["PlutoUI", "Plots", "Statistics", "StaticArrays"])
	
	using PlutoUI
	using Plots
	gr()
	using Statistics
	using Random
	using StaticArrays
end

# ╔═╡ 24bdc21a-533d-11eb-3772-777ca353337b
function run_simulation(buyerCount::Function, sellerCount::Function, nDays=1000)

	prices = []
	push!(prices, 100.0)
	
	
	for i in 1:nDays

		#Set number of buyers and sellers
		numBuyers = buyerCount(i)
		numSellers = sellerCount(i)
		
		#create 0s
		buyers = zeros(numBuyers, 2)
		sellers = zeros(numSellers, 2)

		# initialize prices. Sellers will have an extra offset

		buyers[:, 1] = 5 * randn(numBuyers) .+ prices[end] .- rand(3:6)
		sellers[:, 1] = 5 * randn(numSellers) .+ prices[end] .+ rand(3:6)

		#Sort buyers and sellers
		sort!(sellers, dims=1, rev = true)
		sort!(buyers, dims=1, rev = true)
		
		# Initialize quantity
		buyers[:, 2] = rand(100:1000, numBuyers)
		sellers[:, 2] = rand(100:1000, numSellers)
		
		
		day_prices = []

		# Start trading
		while length(buyers) > 0
			
			match_index = let
				p1 = buyers[1, 1]
				index = -1
				if p1 >= sellers[end, 1]
					index = size(sellers)[1]
				end
				index
			end

			if match_index == -1
				break
			end
			
			seller = sellers[match_index, :]
			buyer = buyers[1, :]
			
			price = mean([seller[1], buyer[1]]) #rand([seller[1], buyer[1]])
			
			quantity = min(buyer[2], seller[2])
			
			sellers[match_index, 2] -= quantity
			buyers[1, 2] -= quantity
			
			push!(day_prices, price)
			
			if buyers[1, 2] <= 0
				buyers = buyers[1:size(buyers,1) .!= 1,: ]
			end
			
			if sellers[match_index, 2] <= 0
				sellers = sellers[1:size(sellers,1) .!= match_index,: ]
			end
			
			
		end
		
		push!(prices, mean(day_prices))
		
	end
	prices
end

# ╔═╡ d5b6da5c-533d-11eb-301a-97284f41e93e
function monte_carlo(simulation::Function, buyerCount::Function, sellerCount::Function; nSimulations=1000, nDays = 1000)
	sims = []
	avg_prices = []
	for i in 1:nSimulations
		push!(sims, simulation(buyerCount, sellerCount, nDays))
	end
	
	for i in 1:nDays
		dayAvg = 0
		for sim in sims
			dayAvg += sim[i]
		end
		
		push!(avg_prices, dayAvg / nSimulations)
	end
	sims, avg_prices
end

# ╔═╡ 83081106-5499-11eb-05c6-250a1a635d9a
run_simulation(x -> 100, x -> 100, 500)

# ╔═╡ 59c7de24-535a-11eb-1bcf-b98fabda000a
plot(1:1001, run_simulation(x -> 100, x -> 100, 1000))

# ╔═╡ 5a7f7136-54ce-11eb-2efc-3bd9d4763e62
function run_insider(buyerCount::Function, sellerCount::Function, nDays=1000, notion = 10, richness = 10000, buyer_insider = true, num=1)

	prices = []
	push!(prices, 100.0)

	insider_buyer_count = 0
	normal_buyer_count = 0
	insider_seller_count = 0
	normal_seller_count = 0

	theoretical_price = 0
	for i in 1:nDays

		#Set number of buyers and sellers
		numBuyers = buyerCount(i, notion, buyer_insider, num)
		numSellers = sellerCount(i, notion, !buyer_insider, num)

		#create 0s
		buyers = zeros(numBuyers, 2)
		sellers = zeros(numSellers, 2)

		# initialize prices. Sellers will have an extra offset

		buyers[:, 1] = 5 * randn(numBuyers) .+ prices[end] .- rand(3:6)
		sellers[:, 1] = 5 * randn(numSellers) .+ prices[end] .+ rand(3:6)			

		
		if i == 150 && buyer_insider
			buyers[1:num, 1] .= prices[end] + 0.5*notion
			buyers[1:num, 2] .= richness
			insider_prices = deepcopy(buyers[1:num, 1][1])

		elseif i == 150
			sellers[1:num, 1] .= prices[end] - 0.5*notion
			sellers[1:num, 2] .= richness
			insider_prices = deepcopy(sellers[1:num, 1][1])
		end
		
		#Sort buyers and sellers
		sort!(sellers, dims=1, rev = true)
		sort!(buyers, dims=1, rev = true)

		# Initialize quantity
		buyers[:, 2] = rand(100:1000, numBuyers)
		sellers[:, 2] = rand(100:1000, numSellers)

		if i == 150 && buyer_insider
			buyers_c = deepcopy(buyers)
			sellers_c = deepcopy(sellers)

			insider_index = findall(x -> x == insider_prices, buyers_c)[1]
			insider_index = insider_index[1]
			buyers_c[insider_index, 2] = 0
			
		elseif i == 150
			buyers_c = deepcopy(buyers)
			sellers_c = deepcopy(sellers)
			
			insider_index = findall(x -> x == insider_prices, sellers_c)[1]
			insider_index = insider_index[1]
			sellers_c[insider_index, 2] = 0
		end

		day_prices = []

		# Start trading
		while length(buyers) > 0

			match_index = let
				p1 = buyers[1, 1]
				index = -1
				if p1 >= sellers[end, 1]
					index = size(sellers)[1]
				end
				index
			end

			if match_index == -1
				break
			end

			seller = sellers[match_index, :]
			buyer = buyers[1, :]

			price = mean([seller[1], buyer[1]])

			quantity = min(buyer[2], seller[2])

			sellers[match_index, 2] -= quantity
			buyers[1, 2] -= quantity

			if i == 150
				if buyer_insider
					if price != insider_prices
						insider_buyer_count += quantity
					end
					insider_seller_count += quantity
				else
					if price != insider_prices
						insider_seller_count += quantity
					end
					insider_buyer_count += quantity
				end
			end


			push!(day_prices, price)

			if buyers[1, 2] <= 0
				buyers = buyers[1:size(buyers,1) .!= 1,: ]
			end

			if sellers[match_index, 2] <= 0
				sellers = sellers[1:size(sellers,1) .!= match_index,: ]
			end


		end

		push!(prices, mean(day_prices))

		
		if i == 150
			buyers = buyers_c
			sellers = sellers_c
			day_prices = []
			
			while length(buyers) > 0

				match_index = let
					p1 = buyers[1, 1]
					index = -1
					if p1 >= sellers[end, 1]
						index = size(sellers)[1]
					end
					index
				end

				if match_index == -1
					break
				end

				seller = sellers[match_index, :]
				buyer = buyers[1, :]

				price = mean([seller[1], buyer[1]])

				quantity = min(buyer[2], seller[2])

				sellers[match_index, 2] -= quantity
				buyers[1, 2] -= quantity

				normal_buyer_count += quantity
				normal_seller_count += quantity
				
				push!(day_prices, price)

				if buyers[1, 2] <= 0
					buyers = buyers[1:size(buyers,1) .!= 1,: ]
				end

				if sellers[match_index, 2] <= 0
					sellers = sellers[1:size(sellers,1) .!= match_index,: ]
				end


			end
		
			theoretical_price = mean(day_prices)
			
		end

	end
	buyer_loss = (normal_buyer_count - insider_buyer_count) * (theoretical_price - mean(prices[151:180]))
	
	seller_loss = (normal_seller_count - insider_seller_count) * (theoretical_price - mean(prices[151:180]))
	
	tot_loss = buyer_loss + seller_loss
	if !buyer_insider
		tot_loss = -tot_loss
	end
	prices, tot_loss
end

# ╔═╡ 31f35fa8-54f0-11eb-20b4-696f35ef661e
a = [1]

# ╔═╡ 3474d5d8-54f0-11eb-1716-0783f0c1d7f3
a[1]

# ╔═╡ bf9935ac-53fc-11eb-02c8-bfcecb94b4d8
begin
	function insiderBuyerCount(i, notion, buyer_insider=true, num = 1)
		if i == 150 && buyer_insider
			return 100 + num
		elseif i in 151:180 && buyer_insider
			return 100 + 3*notion
		else
			return 100
		end
	end
	
	function insiderSellerCount(i, notion, seller_insider=false, num=1)
		if i == 150 && seller_insider
			return 100 + num
		elseif i in 151:180 && seller_insider
			return 100 + 3*notion
		else
			return 100
		end
	end
end

# ╔═╡ 515fc616-548b-11eb-217b-89c884102eec
function monte_carlo(simulation::Function, buyerCount::Function, sellerCount::Function, notion; nSimulations=1000, nDays = 1000, richness = 1000, buyer_insider = true, num = 1)
		
	sims = []
	avg_prices = []
	losses = []
	for i in 1:nSimulations
		
		sim, loss = simulation(buyerCount, sellerCount, nDays, notion, richness, buyer_insider)
		
		push!(sims, sim)
		push!(losses, loss)
	end
	
	for i in 1:nDays
		dayAvg = 0
		for sim in sims
			dayAvg += sim[i]
		end
		
		push!(avg_prices, dayAvg / nSimulations)
	end
	sims, avg_prices, mean(losses)
end

# ╔═╡ bdb882de-5342-11eb-10e7-0f8f85b014cd
sims, monte = monte_carlo(run_simulation, x -> 100, x -> 100, nSimulations=1000, nDays=500)

# ╔═╡ da322086-4f6a-11eb-1493-b5d1f6347a1b
monte, length(monte)

# ╔═╡ 8ea49b34-4f6b-11eb-144a-79c8752afa9f
plot(1:500, monte, ylims = (90, 110))

# ╔═╡ 59b87d42-5343-11eb-30e5-a17de2569e52
length(sims[1]), length(sims[1][1])

# ╔═╡ 48592510-5343-11eb-0654-3ff66c4420fb
identified_sims = let
	
	max = 1
	min = 1
	med = 1
	
	for i in 1:length(sims)
		sim = sims[i]
		
		if sim[end] > sims[max][end]
			max = i
		end
		
		if sim[end] < sims[min][end]
			min = i
		end
		
		if abs(sim[end] - 100) < abs(sims[med][end] - 100)
			med = i
		end
	end
	(sims[min], sims[med], sims[max])	
end

# ╔═╡ d7cf9f3a-5343-11eb-17b1-3d6b10fee691
let
	min = identified_sims[1]
	med = identified_sims[2]
	max = identified_sims[3]
	
	p1 = plot(1:501, min, label="Bearish Example", legend=:topleft)
	
	plot!(p1, 1:501, med, label="Stable Example (With Trends)")
	plot!(p1, 1:501, max, label="Bearish Example")
	p1
end

# ╔═╡ b2c33d44-53fe-11eb-0ede-f3b14c1f5970
sims_insider, monte_insider, loss = monte_carlo(run_insider, insiderBuyerCount, insiderSellerCount, 15, nSimulations=1000, nDays=500, richness=5000, buyer_insider=false)

# ╔═╡ 549fa7e2-53ff-11eb-0933-01d105588855
plot(1:500, monte_insider)  #, ylims = (90, 110))

# ╔═╡ Cell order:
# ╟─391c0030-4f23-11eb-118d-7d4a50bbe3aa
# ╟─24bdc21a-533d-11eb-3772-777ca353337b
# ╟─d5b6da5c-533d-11eb-301a-97284f41e93e
# ╠═83081106-5499-11eb-05c6-250a1a635d9a
# ╠═bdb882de-5342-11eb-10e7-0f8f85b014cd
# ╠═59c7de24-535a-11eb-1bcf-b98fabda000a
# ╠═da322086-4f6a-11eb-1493-b5d1f6347a1b
# ╠═8ea49b34-4f6b-11eb-144a-79c8752afa9f
# ╠═59b87d42-5343-11eb-30e5-a17de2569e52
# ╠═48592510-5343-11eb-0654-3ff66c4420fb
# ╠═d7cf9f3a-5343-11eb-17b1-3d6b10fee691
# ╠═5a7f7136-54ce-11eb-2efc-3bd9d4763e62
# ╠═31f35fa8-54f0-11eb-20b4-696f35ef661e
# ╠═3474d5d8-54f0-11eb-1716-0783f0c1d7f3
# ╠═bf9935ac-53fc-11eb-02c8-bfcecb94b4d8
# ╠═515fc616-548b-11eb-217b-89c884102eec
# ╠═b2c33d44-53fe-11eb-0ede-f3b14c1f5970
# ╠═549fa7e2-53ff-11eb-0933-01d105588855
