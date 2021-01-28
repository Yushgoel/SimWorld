### A Pluto.jl notebook ###
# v0.12.18

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 391c0030-4f23-11eb-118d-7d4a50bbe3aa
begin
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.add(["PlutoUI", "Plots", "Statistics"])
	
	using PlutoUI
	using Plots
	plotlyjs()
	using Statistics
	using Random
end

# ╔═╡ 539fd85c-587e-11eb-1739-e1a12d43d05b
md"""
# But Why is Insider Trading Bad?
Ayush Goel
"""

# ╔═╡ 64993874-587e-11eb-044a-55fa78389210
md"""

We first need to build a model that can output stock prices based on the number of buyers and sellers. The idea is essentially the following:
1. If there are more sellers than buyers, the price should ideally go down that day.
2. If there are more buyers than sellers, the price should ideally go up that day.
3. If the number of buyers and sellers are the same, the price should remain relatively stable.

We also don't want a model where we just pre-define how much the stock price should go up or down by. It has to be dependent on the market, and some other uncontrollable factors. Also, we want a system where number of extra buyers or sellers in the market also has an impact on the stock price.
"""

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

# ╔═╡ fea0b03e-5fa7-11eb-2a39-617da3d60039
rand(3:6)

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

# ╔═╡ 07ead318-587f-11eb-272d-2fe7d11ea220
md"""
## Demand Supply Based Price Simulator
"""

# ╔═╡ 155fa102-587f-11eb-3794-49b5f4f195b5
md"""
This system works almost how most stock brokers execute trades:

1. All buyers and sellers place their price and quantity at the beginning of the day.
	Here, I am making the assumption that all trades are placed in the beginning of the day. This isn't very true, but makes the simulation work easier. The only impact this will have is that the closing price will always be the highest transaction price of the day. To work around this, instead of using the last price as the closing price, we take the mean of all prices (of today's transactions) as the closing price.

2. Buyers and sellers are sorted. The most highest price buyer is paired up with the lowest price seller.
	There will be a disparity between prices, so the transaction price is the mean of both prices. 

3. Quantity of transaction is the minimum quantity between the buyer and seller.

4. Trading continues for the day until no more trades can be made. The closing price is now the mean of all transaction prices for the day.
"""

# ╔═╡ a8bd9c74-587f-11eb-3ff7-a1e5e0f7463f
md"""
Here is a plot of the price for 500 trading days. Note that the number of buyers and sellers is the same in this scenario.
"""

# ╔═╡ 59c7de24-535a-11eb-1bcf-b98fabda000a
plot(1:501, run_simulation(x -> 100, x -> 100, 500), xlabel = "Number of Days", ylabel = "Price", legend= false)

# ╔═╡ a6e7a93a-587f-11eb-3d77-c7f7afbe9d91
md"""
As we can see, there is too much noise. The reason is that prices are randomly generated (as we want only number of buyers and sellers to impact price in our simulation). This leads to a lot of noise. In fact, even between runs, the final price can vary anywhere from 200 to 20!

If we have an extremely noisy simulation, seeing the impact of the insider will be hard. To fix this, let's run a monte carlo simulation. Intuitively, we just run the same (above) simulation many many times (in our case 1000), and then average the prices. This should give a relatively flat line, since the random numbers should average out to no change.
"""

# ╔═╡ 0210619c-5880-11eb-23cc-e38df594d0aa
md"""
So we indeed get a stable line, with minor fluctations. Taking a larger number of simuations would be better, but take much longer.
"""

# ╔═╡ ff80a3bc-587f-11eb-3d75-b19a94901307
md"""
Just a fun sidenote

All of the below simulations were run with the same parameters (all 3 were used in the average to make the plot above).
"""

# ╔═╡ 68dce4a6-5880-11eb-3bdb-a94d8987a452
md"""
Despite this, there are such significant trends in the price. The price ranges anywhere from 175 to 50 (numbers may be different for every run)! The reason is that random numbers can have "visible" trends in the short run, but in the long run they should average out. This is why, sometimes a bad investment decision can still give good returns, and a good investment decision can still give bad returns. Luck is an important factor!

Another thing to note is that sometimes we may feel like there are trends in the stock price, whereas they are just insiginficant artifacts. The trend can reverse at any point in time. You can see this with the red line. Sometimes, the price seems to go up consistently, but then suddenly reverses and goes back to 100.


Back to insider trading...
"""

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
plot(1:500, monte, ylims = (90, 110), xlabel = "Number of Days", ylabel = "Price", legend=false)

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
	
	p1 = plot(1:501, min, label="Bearish Example", legend=:topleft, xlabel = "Number of Days", ylabel = "Price")
	
	plot!(p1, 1:501, med, label="Stable Example (With Trends)", xlabel = "Number of Days", ylabel = "Price")
	plot!(p1, 1:501, max, label="Bullish Example", xlabel = "Number of Days", ylabel = "Price")
	p1
end

# ╔═╡ fbea559e-5880-11eb-1767-776bd8cb30d4
md"""
For insider trading, we just add an extra buyer or seller (the insider), but his price is predetermined. He has insider news, and so will price higher (or lower) than the market based on the size of the news. Let's take an example:

If the insider receives news that the company is going to announce a major product next week, the insider will try and buy large quantities of the stock today. Also, to make sure the insider is able to buy as much as possible, the insider will be ready to buy at a slightly higher price so that as many sellers as possible are paired up with the insider. Next week, the news is officially released, and the market now has more interested buyers than sellers. This causes the price to rise, and the insider makes a profit. 

The exact opposite is true for negative news: The insider will now sell the stock at a lower price in order to reduce losses (or even short the market).

The below nobs allow you to modify the simulation.

Price Adjustment From News refers to how positive or negative the news is. A higher value means that the stock price should go up (or down) more, and a smaller value means that the stock price shouldn't expect much change.

There can be negative and positive news, so the checkbox is to handle that. When ticked, there will be a positive news released.

The aggressiveness of the Insider is the quantity that the insider buys or sells. Higher aggressiveness could be due to the reliability of insider news, or even the insider having more money to spare.
"""

# ╔═╡ a4e8c2f0-56ee-11eb-17e9-cba5cfa02ce6
md"""Price Adjustment From News: 
$(@bind notion Slider(5:5:20, show_value = true, default = 10))"""

# ╔═╡ 2680c33a-55a0-11eb-2637-737e78fb5b7d
md"""


Positive Insider News: $(@bind buyer_insider CheckBox())  (Empty Box means that there is negative insider news)

Aggressiveness of Insider (Quantity Bought): $(@bind richness Slider(1000:500:10000, show_value = true))
"""

# ╔═╡ b2c33d44-53fe-11eb-0ede-f3b14c1f5970
sims_insider, monte_insider, loss = monte_carlo(run_insider, insiderBuyerCount, insiderSellerCount, notion, nSimulations=1000, nDays=500, richness=richness, buyer_insider=buyer_insider)

# ╔═╡ 549fa7e2-53ff-11eb-0933-01d105588855
plot(1:500, monte_insider, xlabel = "Number of Days", ylabel = "Price", legend=false)

# ╔═╡ 045190fe-587b-11eb-3b0e-57eafb35fecf
md"""Loss to society: $(floor(Int, loss))"""

# ╔═╡ Cell order:
# ╟─539fd85c-587e-11eb-1739-e1a12d43d05b
# ╟─64993874-587e-11eb-044a-55fa78389210
# ╟─391c0030-4f23-11eb-118d-7d4a50bbe3aa
# ╠═24bdc21a-533d-11eb-3772-777ca353337b
# ╠═fea0b03e-5fa7-11eb-2a39-617da3d60039
# ╟─d5b6da5c-533d-11eb-301a-97284f41e93e
# ╟─bdb882de-5342-11eb-10e7-0f8f85b014cd
# ╟─07ead318-587f-11eb-272d-2fe7d11ea220
# ╟─155fa102-587f-11eb-3794-49b5f4f195b5
# ╟─a8bd9c74-587f-11eb-3ff7-a1e5e0f7463f
# ╟─59c7de24-535a-11eb-1bcf-b98fabda000a
# ╟─a6e7a93a-587f-11eb-3d77-c7f7afbe9d91
# ╟─da322086-4f6a-11eb-1493-b5d1f6347a1b
# ╟─8ea49b34-4f6b-11eb-144a-79c8752afa9f
# ╟─0210619c-5880-11eb-23cc-e38df594d0aa
# ╟─48592510-5343-11eb-0654-3ff66c4420fb
# ╟─ff80a3bc-587f-11eb-3d75-b19a94901307
# ╟─d7cf9f3a-5343-11eb-17b1-3d6b10fee691
# ╟─68dce4a6-5880-11eb-3bdb-a94d8987a452
# ╟─5a7f7136-54ce-11eb-2efc-3bd9d4763e62
# ╠═bf9935ac-53fc-11eb-02c8-bfcecb94b4d8
# ╟─515fc616-548b-11eb-217b-89c884102eec
# ╟─fbea559e-5880-11eb-1767-776bd8cb30d4
# ╟─a4e8c2f0-56ee-11eb-17e9-cba5cfa02ce6
# ╟─2680c33a-55a0-11eb-2637-737e78fb5b7d
# ╟─b2c33d44-53fe-11eb-0ede-f3b14c1f5970
# ╟─549fa7e2-53ff-11eb-0933-01d105588855
# ╟─045190fe-587b-11eb-3b0e-57eafb35fecf
