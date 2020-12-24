### A Pluto.jl notebook ###
# v0.12.17

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

# ╔═╡ 9cdd996e-4154-11eb-0d80-43c01f6a93b0
begin
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.add(["PlutoUI", "Plots"])

	using PlutoUI
	using Plots
	gr()
	println("")
end

# ╔═╡ de91c494-41bc-11eb-3d49-6d14bfde3453
md"""
# Microeconomics - Demand and Supply Simulated
Ayush Goel

In Microeconomics, the concept of demand and supply representing the market was a bit confusing to me. I didn't really understand how all producers and consumers would end up coming to a single consensus, and form a stable equilibrium, rather than constantly changing the prices. So I thought of making a simulation to see what actually happens. 

In this simulation, I made sure that every consumer and producer starts off with a completely random idea on what the right price should be. It turns out that all producers and consumers actually end up converging to the exact same point! Exactly what microeconomics predicts, so this theory really does work in practice. What's even more interesting is that no matter what consumer and producers initially think the price should be, they will update their beliefs and always end up at the same point!

Here, I want to simulate a few basic concepts related to demand and supply: market equilibrium, taxes, price floors and price ceils. 

*This is the interactive version of the simulation. All sliders and buttons are interactive and can be changed by the viewer to see the impact on the simulation.*
"""

# ╔═╡ bb89659a-41de-11eb-0956-2d9707f79ae3
md"""
The first task is to generate the supply and demand curves. In my simulation, the supply and demand curves will only represent the limit prices for consumers and producers. This means that if a consumer has a limit of $1.0, they would be happy purchasing it for a lower price, but will never cross $1.0. Similarly, if a producer has a limit of $0.50, he will be happy selling it for a higher price, but will never go lower than this.

For now, let's assume that the price of the good varies from $0 - $1. For the demand curve, we can simply generate random numers between 0 and 1 (with equal probability) and then sort them in descending order. This will give a downward sloping curve. For the supply curve, we do the same but sort it in ascending order (to make it upward sloping). This should give us a representative market along with appropriate curves.

The slider below controls the number of producers = number of consumers in the market. 100 means that there are 100 producers and 100 consumers. A larger market size for the simulation will better show what economics models predict.
"""

# ╔═╡ 3a84b6fc-415a-11eb-39e9-17acd55bab74
md""" Number of Producers and Consumers $(@bind num_players Slider(5:100, show_value=true, default=100))"""

# ╔═╡ ca3c0d9e-4154-11eb-11bf-a9b0a3a48040
begin
	producers = rand(num_players)
	sort!(producers)
	consumers = rand(num_players)
	sort!(consumers, rev=true)
	index = [i for i in 1:num_players]
	println("Generated People")
end

# ╔═╡ 02e816ee-415a-11eb-0250-4bd6a5f6cb4a
begin
	plot(index, producers, label = "Producers")
	plot!(index, consumers, xlabel="Quantity", ylabel = "Price", title="Supply Demand Market", label = "Consumers")
end

# ╔═╡ a414898a-45ba-11eb-0161-5b519c16d585
md"""
Apart from this, consumers and producers also have expectations about what the market price should be (also called producer and consumer prices). This will be random value within their limit, but not necessarily at their limit. To take an example, if you as a consumer can afford to spend $100 on buying a chair (this is your limit), it doesn't mean that you think this is the fair value of the chair. You might bargain as much as possible and be rigid to buy it at any price above $50 (this is your expectation). 

The collective expectations of consumers and producers is what determines the market price. We will represent the expectations with dots (they are color coded to match whether they are consumers or producers).


"""

# ╔═╡ 55965e12-41ac-11eb-2bc6-e5c3d4cef731
begin
	cons_expectations = clamp.(consumers .- abs.((0.2 .* rand(length(consumers)))), 0, 10)
	prod_expectations = clamp.(producers .+ abs.((0.2 .* rand(length(producers)))), 0, 10)
	println("")
end

# ╔═╡ 24f5cf62-45bb-11eb-3961-f982843bfa88
let
	plot(index, producers, label = "Producers")
	plot!(index, consumers, xlabel="Quantity", ylabel = "Price", title="Supply Demand Market", label = "Consumers")
	scatter!(index, cons_expectations, m=:o, color="orange", label= "Consumer Prices")
	scatter!(index, prod_expectations, m=:o, color="blue", label = "Producer Prices")
end

# ╔═╡ 37408ee8-45bb-11eb-16fe-473ae98a2700
md"""
As you can see, no blue dot goes below the blue line (corresponding to supply curve) and no orange dot goes above the orange line (corresponding to the demand curve).

The dots seem randomly spread because they are. We haven't run the simulation yet, so the dots haven't gotten a chance to converge yet.

In this simulation, we will simulate the market over multiple trading days. Now let's lay down the rules for how each trading day in the market will work:

1. A random consumer and producer will be paired with each other. If the consumer's expectation (or price) is more than the producer's expectation (or price), then they will make a trade. 
	If such a trade happens, then the producer will increase his expectation (because he got a deal so easily, so can increase his price), whereas the consumer will reduce his expectation (he also got a deal so easily, so could probably get away paying a little less).
2. If the consumer's expectation is less than the producer's expectation, then we check if the consumer's limit is more than the producer's limit. If it is, then they do some bargaining and still make a trade (since they are still both better off making a trade).
	If such a trade happens, then the producer will decrease his expectation (he had to bargain to get a deal, and bargaining is a risky affair). On the other hand, the consumer will increase his expectation (same reason, he doesn't want to risk not buying something, even though he can afford to).

3. Trading continues like this until no more trades can be made.
	Now, any producers who have not made a trade will decrease their expectations a lot (they didn't get a sale so have no choice but to reduce prices). Any consumers who didn't make a trade will increase their expectations a lot (they could buy anything, so have no choice but to increase prices and attract producers).

**Remember that throughout, the expectations will always be clamped to the limits (i.e. a producer's expectation will never be lower than his ability, and a producer's expectation will never be more than his ability).**

"""

# ╔═╡ 3124e682-41bd-11eb-001a-6d6ce348f0b1
md""" ## Market Equilibrium

This is the first main concept learnt in microeconomics. 

According to the theory, the equilibrium is where the demand curve intersects the supply curve (the orange line intersecting the blue line). 

So let's see if that is what happens in our simulation. Press the start button to start the simulation. The number 0.1 means that it takes 0.1 seconds for 1 trading day to be executed. Keeping it at this number will allow you to best see the market progress. Going below 0.1 may make the graph lag and you may not see the graph update as it should.

"""

# ╔═╡ 1d007b74-415b-11eb-1795-77f7221ae017
md""" Simulation Speed $(@bind timesteps Clock(0.1))"""

# ╔═╡ 36fc50ee-415a-11eb-239f-8308d348bd3a
begin

	cons_surplus = 0
	prod_surplus = 0
		
	for i in timesteps:timesteps
		
		prods_left = [i for i in 1:length(producers)]
		cons_left = [i for i in 1:length(consumers)]
		timeout = 0
		
		while length(prods_left) > 0
			pair = [0, 0]
			cons_left_index = rand(1:length(cons_left), 1)[1]
			prod_left_index = rand(1:length(prods_left), 1)[1]
			pair[1] = cons_left[cons_left_index]
			pair[2] = prods_left[prod_left_index]

			if cons_expectations[pair[1]] >= prod_expectations[pair[2]]
				cons_expectations[pair[1]] -= 0.01
				prod_expectations[pair[2]] += 0.01
			
				splice!(prods_left, prod_left_index)
				splice!(cons_left, cons_left_index)
				
				cons_surplus += (consumers[pair[1]] - cons_expectations[pair[1]])
				prod_surplus += (prod_expectations[pair[2]] - producers[pair[2]])
				timeout = 0

			else
				if consumers[pair[1]] > producers[pair[2]] && (consumers[pair[1]] > prod_expectations[pair[2]])
					
					if (consumers[pair[1]] - cons_expectations[pair[1]]) > (prod_expectations[pair[2]] - producers[pair[2]])
						cons_expectations[pair[1]] += 0.01
						prod_expectations[pair[2]] -= 0.01

						splice!(prods_left, prod_left_index)
						splice!(cons_left, cons_left_index)
						
						cons_surplus += (consumers[pair[1]] - cons_expectations[pair[1]])
						prod_surplus += (prod_expectations[pair[2]] - producers[pair[2]])
						timeout = 0
							
					end
					missing
				else
					timeout += 1					
				end

			end
			
			if timeout == 50
				break
			end
			
				
			# else
			# 	cons_expectations[pair[1]] += 0.01
			# 	prod_expectations[pair[2]] -= 0.01			
			# end

		end
		
		for i in 1:length(prods_left)
			
			j = prods_left[i]
			prod_expectations[j] -= 0.01
			prod_expectations[j] = clamp(prod_expectations[j], producers[j], 10)
		end
		
		for i in 1:length(cons_left)
			j = cons_left[i]
			cons_expectations[j] += 0.01
			cons_expectations[j] = clamp(cons_expectations[j], 0, consumers[j])
		end
	end		
	p1 = plot(index, producers, label = "Producers" )
	plot!(index, consumers, xlabel="Quantity", ylabel = "Price", title="Supply Demand Market", label = "Consumers")
	scatter!(index, cons_expectations, m=:o, color="orange", label= "Consumer Prices")
	scatter!(index, prod_expectations, m=:o, color="blue", label = "Producer Prices")
	
	p2 = bar(["Producers", "Consumers", "Market"], [prod_surplus, cons_surplus, prod_surplus + cons_surplus], legend = false, title="Surplus", size=(600, 800))
	
	plot(p1, p2, layout=(2, 1))
end

# ╔═╡ 339f9e22-41be-11eb-1ea9-1b2583945bf6
md"""
After running it for a while, you should be able to see 2 clear trends:

1. All of the dots on the right of the intersection (between demand and supply curves) have their prices stuck to their limits.

	The reason is that the consumers on the right simply can't afford to pay the market price. They adjust their expectations to be as high as possible (their limit), but still don't get a deal. That's why their dots are stuck to the curve. Similarly, the producers on the right simply can't sell a product at the market price, because their limit is higher than that. Thus, they reduce their expectations as much as possible, but can't beyond a point.

2. All of the dots on the left of the intersection form a straight line, with the height = to the height of the intersection.

	This is exactly what equilibrium is. All producers and consumers can to the same consensus as to what the price should be. Notice how in the simulation, every producer and consumer was designed to act in a self-interested way. There was no collusion or any thought about society, yet they all figure out that the equilibrium price is the best possible (this is the principle of the Invisible Hand). 

Also note the value of the surplus at the end, we will use it to compare the effect of different government policies later.
"""

# ╔═╡ 6e24a652-41be-11eb-3699-f553c77ff31b
md"""



## Taxes

Now let's examine the impact of a government policy on the free market. It is repeated time and again that any intervention in free markets (often) leads to inefficiencies in the market. Let's simulate this and see if the claim is right.

The first government policy we will examine is tax. We will simulate specific indirect tax, which is levied when the good is sold and is constant irrespective of the price. Also, here we will assume that the government expects the producers to pay the tax at the end of the day (the producers are well aware of this policy change).

The slider below will allow you to control the amount of tax levied. Now, a thing to note is that the limits of the producers (the supply curve) has changed. For example, let's assume that there is a tax of 0.1. Now, originally a producer who had a limit of 0.2 could have sold a product at 0.21 and still gone home with a profit. But now, if he sells the same product for 0.21, he has to pay the tax of 0.1, so goes home with only 0.11, which is less than his limit of 0.2. Thus, every producer's limit increases by the value of the supply curve. Why? Because once they make the trade at this price, they pay away the tax and end up at the original supply curve limit.

Let's denote this new limit (Supply curve + tax) with a green line.

Finally, let's run the simulation and see what happens:
"""

# ╔═╡ 33c230c2-41b6-11eb-3626-e3741c798f1b
md""" Tax Amount $(@bind tax Slider(0:0.01:0.25, show_value=true, default=0.1))"""

# ╔═╡ 246aba7c-41b6-11eb-03b0-3fe2498642fa
begin
	producers2 = producers .+ tax
	println("Tax")
end

# ╔═╡ 8f0b880c-41b6-11eb-1674-a740ecbdf88a
md""" Simulation Speed $(@bind timesteps2 Clock(0.1))"""

# ╔═╡ cac7e9a4-41b5-11eb-2903-6986af777e41
begin
	cons_surplus2 = 0
	prod_surplus2 = 0
	
	for i in timesteps2:timesteps2
		
		prods_left = [i for i in 1:length(producers2)]
		cons_left = [i for i in 1:length(consumers)]
		
		timeout = 0
		
		while length(prods_left) > 0
			pair = [0, 0]
			cons_left_index = rand(1:length(cons_left), 1)[1]
			prod_left_index = rand(1:length(prods_left), 1)[1]
			pair[1] = cons_left[cons_left_index]
			pair[2] = prods_left[prod_left_index]

			if cons_expectations[pair[1]] >= (prod_expectations[pair[2]])
				cons_expectations[pair[1]] -= 0.01
				prod_expectations[pair[2]] += 0.01
			
				splice!(prods_left, prod_left_index)
				splice!(cons_left, cons_left_index)
				
				cons_surplus2 += (consumers[pair[1]] - cons_expectations[pair[1]])
				prod_surplus2 += (prod_expectations[pair[2]] - producers[pair[2]] - (tax))
				timeout = 0

			else
				if consumers[pair[1]] > producers2[pair[2]] && (consumers[pair[1]] > prod_expectations[pair[2]])
					
					if (consumers[pair[1]] - cons_expectations[pair[1]]) > (prod_expectations[pair[2]] - producers2[pair[2]])
						cons_expectations[pair[1]] += 0.01
						prod_expectations[pair[2]] -= 0.01

						splice!(prods_left, prod_left_index)
						splice!(cons_left, cons_left_index)
						
						cons_surplus2 += (consumers[pair[1]] - cons_expectations[pair[1]])
						prod_surplus2 += (prod_expectations[pair[2]] - producers[pair[2]] - (tax))
					end
					missing
				else
					timeout += 1					
				end

			end
			
			if timeout == 50
				break
			end
			
				
			# else
			# 	cons_expectations[pair[1]] += 0.01
			# 	prod_expectations[pair[2]] -= 0.01			
			# end

		end
		
		for i in 1:length(prods_left)
			
			j = prods_left[i]
			prod_expectations[j] -= 0.01
			prod_expectations[j] = clamp(prod_expectations[j], producers2[j], 10)
		end
		
		for i in 1:length(cons_left)
			j = cons_left[i]
			cons_expectations[j] += 0.01
			cons_expectations[j] = clamp(cons_expectations[j], 0, consumers[j])
		end
	end		
	
	p3 = plot(index, producers, label = "Producers", color="blue")
	plot!(index, producers2, label = "Producers + Tax", color = "green")
	plot!(index, consumers, xlabel="Quantity", ylabel = "Price", title="Supply Demand Market", label = "Consumers", color="orange")
	scatter!(index, cons_expectations, m=:o, color="orange", label= "Consumer Prices")
	scatter!(index, prod_expectations .- tax, m=:o, color="blue", label = "Producer Prices")
	
	p4 = bar(["Producers", "Consumers", "Market"], [prod_surplus2, cons_surplus2, prod_surplus2 + cons_surplus2], legend = false, title="Surplus", size=(600, 800))
	
	plot(p3, p4, layout=(2, 1))
	
end

# ╔═╡ 4bb6a13c-41d3-11eb-036d-3528e31d7668
md"""
Now when we run the simulation, the consumer and producer prices form two separate lines! They are no longer the same line but have diverged. The reason is the tax. Consumers pay a price along their line, but producers pay the tax afterwards, and end up at the lower price. 

Infact, if you look carefully, the lines are separated exactly by the value of the tax. One thing to note is that the producers don't pay for the entire tax. To verify this, look at the line for consumers. In the free market, it was close to around 0.5, but now (a higher tax amount will show this more clearly) the consumers pay a price significantly higher than 0.5. Thus, the tax is "shared" by consumers and producers.

Also compare the surpluses. If you see, the market surplus is now overall less than in the free market. This is what is meant by how government policies negatively impact the market. Producers and consumers are both unhappy with the tax.
"""

# ╔═╡ 7ff1d5a8-41dc-11eb-330e-47864080ac5c
md"""
## Price Floors
"""

# ╔═╡ c204a204-41dc-11eb-0bed-57edfd530122
md"""
Price Floors are another interesting form of government intervention. Here, the government essentially enforces a regulation where no transaction in the market can occur below the price floor. It is essentially the minimum price a transaction can go. 

However, price floors are not as straightforward as taxes as we even have to consider what to do with the surplus.

	When a price floor is placed above market price, more producers are able to produce and sell at that minimum price, but less consumers are able to buy. Thus, too much of the good is produced, and something has to be done. In the caase of product markets, the government often just buys all of this surplus, which is what we will simulate here.

The logic here is going to be simple. Trading will continue on as it was before, but will have one restriction: if the consumer price is not more than the price floor, then the trade will not occur. This is because if the consumer price is lower, then the trade becomes illegal (for the sake of simplicity, we won't consider any underground markets where such a transaction is possible, only a fully legal and regulated market).


Below is the slider for the price floor (which corresponds to the green line of the graph). You can change it and watch the simulation adapt. (the price floor will only matter if placed above the equilibrium price).
"""

# ╔═╡ 5437f18c-41d6-11eb-2724-7ba6de5b892c
md""" Price Floor $(@bind floor Slider(0:0.01:1, show_value=true))"""

# ╔═╡ df2887cc-41d9-11eb-022e-0d70b44296b7
begin
	floors = [floor for i in 1:length(index)]
	println("Initialized PriceFloor")
end

# ╔═╡ 84f8da0c-41d6-11eb-2617-1143f5dbf53f
md""" Simulation Speed $(@bind timesteps3 Clock(0.1))"""

# ╔═╡ 8fc46eba-41d6-11eb-2cf5-3d6e2d3f7f3d
begin
	cons_surplus3 = 0
	prod_surplus3 = 0
	
	for i in timesteps3:timesteps3
		
		prods_left = [i for i in 1:length(producers2)]
		cons_left = [i for i in 1:length(consumers)]
		
		timeout = 0
		
		while length(prods_left) > 0
			pair = [0, 0]
			cons_left_index = rand(1:length(cons_left), 1)[1]
			prod_left_index = rand(1:length(prods_left), 1)[1]
			pair[1] = cons_left[cons_left_index]
			pair[2] = prods_left[prod_left_index]

			if cons_expectations[pair[1]] >= (prod_expectations[pair[2]]) && cons_expectations[pair[1]] > floor
				cons_expectations[pair[1]] -= 0.01
				prod_expectations[pair[2]] += 0.01
			
				splice!(prods_left, prod_left_index)
				splice!(cons_left, cons_left_index)
				
				cons_surplus3 += (consumers[pair[1]] - cons_expectations[pair[1]])
				prod_surplus3 += (prod_expectations[pair[2]] - producers[pair[2]])
				timeout = 0

			else
				if consumers[pair[1]] > (producers[pair[2]]) && (consumers[pair[1]] > (prod_expectations[pair[2]])) && consumers[pair[1]] > floor
					
					if (consumers[pair[1]] - cons_expectations[pair[1]]) > (prod_expectations[pair[2]] - producers[pair[2]])
						cons_expectations[pair[1]] += 0.01
						prod_expectations[pair[2]] -= 0.01

						splice!(prods_left, prod_left_index)
						splice!(cons_left, cons_left_index)
						
						cons_surplus3 += (consumers[pair[1]] - cons_expectations[pair[1]])
						prod_surplus3 += (prod_expectations[pair[2]] - producers[pair[2]])
					end
					missing
				else
					timeout += 1					
				end

			end
			
			if timeout == 50
				break
			end


		end
		
		for i in 1:length(prods_left)
			
			j = prods_left[i]
			if prod_expectations[j] <= floor
				prod_surplus3 += (floor) - producers[j]
				prod_expectations[j] += 0.01
			else
				prod_expectations[j] -= 0.01
			end
			# prod_expectations[j] -= 0.01 #Government Buys Surplus
			prod_expectations[j] = clamp(prod_expectations[j], producers[j], 10)
		end
		
		for i in 1:length(cons_left)
			j = cons_left[i]
			cons_expectations[j] += 0.01
			cons_expectations[j] = clamp(cons_expectations[j], 0, consumers[j])
		end
	end		
	
	p5 = plot(index, producers, label = "Producers", color="blue")
	plot!(index, floors, label = "Price Floor", color = "green")
	plot!(index, consumers, xlabel="Quantity", ylabel = "Price", title="Supply Demand Market", label = "Consumers", color="orange")
	scatter!(index, cons_expectations, m=:o, color="orange", label= "Consumer Prices")
	scatter!(index, prod_expectations, m=:o, color="blue", label = "Producer Prices")
	
	p6 = bar(["Producers", "Consumers", "Market"], [prod_surplus3, cons_surplus3, prod_surplus3 + cons_surplus3], legend = false, title="Surplus", size=(600, 800))
	
	plot(p5, p6, layout=(2, 1))
	
end

# ╔═╡ 6ca6020c-41dd-11eb-2d8f-316c599b2a1f
md"""

If you play with the simulation, you should notice 2 different scenarios:

1. If the price floor is below the market price, nothing happens and it is essentially the free market all over again.
	This intuitively makes sense as consumers and producers are already making transactions at a price higher than the price floor, so it doesn't make a difference to them.

2. When the price floor is above market price, a large number of producers but a small number of consumers are participating in the market.
	This also makes sense as now when the price floor is above the market price, more producers are able to produce and sell. Producers don't even need to decrease their expectations when a consumer doesn't buy from them since the government will have to do it at the price floor anyway.

Looking at the surplus, we see that the producer surplus has gone up dramatically, but the consumer surplus has gone down even more. That's why, in the end the market surplus is still less than the free market economy.

"""

# ╔═╡ ed48dba8-41ee-11eb-0a6e-a79198da629f
md"""
## Price Ceiling

Price Ceiling are exactly the opposite as price floors. Instead of having a minimum transaction price, there is now a maximum transaction price.

In Price Floors, we realized that there was a surplus created since more producers are able to produce. In Price Ceils, there is a shortage created, as now many more consumers can afford to buy the good, but there are very few producers.

In the Price Floor, we saw that the government could step in and buy the surplus of the producers. But in the Price Ceil, the government can't easily fix the shortage. If they tried, they would have to find producers to buy from or hire them, but there are no more producers left (as they are all in the market)! However, there is still an opportunity to import the good.

For this reason, we will just assume that the government doesn't step in.

The slider below allows you to control the price ceiling (green line).
"""

# ╔═╡ 2098b5ce-41e9-11eb-2d68-a56b52a114fa
md""" Price Ceiling $(@bind ceil Slider(0:0.01:1, show_value=true, default=1))"""

# ╔═╡ 48e54722-41e9-11eb-0938-af78a0f6770a
md""" Simulation Speed $(@bind timesteps4 Clock(0.1))"""

# ╔═╡ 31988b6a-41e9-11eb-33e2-d59ff1e77477
begin
	ceils = [ceil for i in 1:length(index)]
	println("Initialized PriceFloor")
end

# ╔═╡ 58d75242-41e9-11eb-08f2-2b370a268a87
begin
	cons_surplus4 = 0
	prod_surplus4 = 0
	
	for i in timesteps4:timesteps4
		
		prods_left = [i for i in 1:length(producers)]
		cons_left = [i for i in 1:length(consumers)]
		
		timeout = 0
		
		while length(prods_left) > 0
			pair = [0, 0]
			cons_left_index = rand(1:length(cons_left), 1)[1]
			prod_left_index = rand(1:length(prods_left), 1)[1]
			pair[1] = cons_left[cons_left_index]
			pair[2] = prods_left[prod_left_index]

			if cons_expectations[pair[1]] >= (prod_expectations[pair[2]]) && prod_expectations[pair[2]] < ceil
				cons_expectations[pair[1]] -= 0.01
				prod_expectations[pair[2]] += 0.01
			
				splice!(prods_left, prod_left_index)
				splice!(cons_left, cons_left_index)
				
				cons_surplus4 += (consumers[pair[1]] - cons_expectations[pair[1]])
				prod_surplus4 += (prod_expectations[pair[2]] - producers[pair[2]])
				timeout = 0

			else
				if (consumers[pair[1]] > (prod_expectations[pair[2]])) && prod_expectations[pair[2]] < ceil

					if (consumers[pair[1]] - cons_expectations[pair[1]]) > (prod_expectations[pair[2]] - producers[pair[2]])

						cons_expectations[pair[1]] += 0.01
						prod_expectations[pair[2]] -= 0.01
						prod_expectations[pair[2]] = clamp(prod_expectations[pair[2]], producers[pair[2]], 100)
						
						splice!(prods_left, prod_left_index)
						splice!(cons_left, cons_left_index)

						cons_surplus4 += (consumers[pair[1]] - cons_expectations[pair[1]])
						prod_surplus4 += (prod_expectations[pair[2]] - producers[pair[2]])
					end
				else
					timeout += 1									
				end

			end

			
			if timeout == 50
				break
			end
			
				
			# else
			# 	cons_expectations[pair[1]] += 0.01
			# 	prod_expectations[pair[2]] -= 0.01			
			# end

		end
		
		for i in 1:length(prods_left)
			
			j = prods_left[i]
			prod_expectations[j] -= 0.01

			prod_expectations[j] = clamp(prod_expectations[j], producers[j], 10)
		end
		
		for i in 1:length(cons_left)
			j = cons_left[i]
			if consumers[j] < ceil
				cons_expectations[j] += 0.00
			else
				cons_expectations[j] += 0.001 / (length(cons_left) / 100)	
			end
			 # No penalty! There is a shortage.
			cons_expectations[j] = clamp(cons_expectations[j], 0, consumers[j])
		end
	end		
	
	p7 = plot(index, producers, label = "Producers", color="blue")
	plot!(index, ceils, label = "Price Ceiling", color = "green")
	plot!(index, consumers, xlabel="Quantity", ylabel = "Price", title="Supply Demand Market", label = "Consumers", color="orange")
	scatter!(index, cons_expectations, m=:o, color="orange", label= "Consumer Prices")
	scatter!(index, prod_expectations, m=:o, color="blue", label = "Producer Prices")
	
	p8 = bar(["Producers", "Consumers", "Market"], [prod_surplus4, cons_surplus4, prod_surplus4 + cons_surplus4], legend = false, title="Surplus", size=(600, 800))
	
	plot(p7, p8, layout=(2, 1))
	
end

# ╔═╡ d86b02c2-41ee-11eb-3bc0-b1e33a80922f
md"""
Once again, we notice 2 different cases in the simulation:

1. If the price ceil is above the market price, nothing changes.
	This happens for the exact same reason as the price floor. Producers are anyways selling the product at a price lower than the price floor, so there is no issue.

2. If the price ceil is below the market price, a large number of consumers want to participate, but only a few producers are left. 

	This seems intuitive as well since now the product's price falls within the limits for more consumers. A thing to note here is that just because all of the consumers'  expectations fall to the price ceil, it doesn't mean that all of them are able to buy the good, only some are. In fact, in the price floor, everyone had settled quickly since the government was buying the excess. Here, there is still some movement, so this is slightly more unstable.

While you would expect consumer surplus to increase drastically, it doesn't. This is again due to the fact that the government isn't filling in the shortage, so not all consumers get the benefit of the low price. Overall, the market surplus also goes down.
"""

# ╔═╡ 49e61a86-45de-11eb-224d-d1ad42f92225
md"""

In all of the different scenarios we have simulated here, the end outcome has matched what microeconomics predicts. I think this shows how good a model demand and supply is, and gives a better understanding of the principle of the Invisible hand, and how everyone comes to the same consensus.

## Limitations:

1. We have built a very simplified decision framework for consumers and producers. In reality, the thought process may be much more complicated. For example, in a real market, there is a chance that no bargaining will happen, so the producer will never reduce their prices. 
2. In reality, people are also biased. This means that sometimes, people wouldn't update their beliefs in the right way, or some irrelevant information may factor into their prices. For example, the anchoring bias may completely hinder the expectations for consumers and producers, so they may find it hard to converge.

A more detailed simulation could be made, but I think this illustrates the model well enough, while being simple.
"""

# ╔═╡ Cell order:
# ╟─de91c494-41bc-11eb-3d49-6d14bfde3453
# ╟─9cdd996e-4154-11eb-0d80-43c01f6a93b0
# ╟─bb89659a-41de-11eb-0956-2d9707f79ae3
# ╟─3a84b6fc-415a-11eb-39e9-17acd55bab74
# ╟─ca3c0d9e-4154-11eb-11bf-a9b0a3a48040
# ╟─02e816ee-415a-11eb-0250-4bd6a5f6cb4a
# ╟─a414898a-45ba-11eb-0161-5b519c16d585
# ╟─55965e12-41ac-11eb-2bc6-e5c3d4cef731
# ╟─24f5cf62-45bb-11eb-3961-f982843bfa88
# ╟─37408ee8-45bb-11eb-16fe-473ae98a2700
# ╟─3124e682-41bd-11eb-001a-6d6ce348f0b1
# ╟─1d007b74-415b-11eb-1795-77f7221ae017
# ╟─36fc50ee-415a-11eb-239f-8308d348bd3a
# ╟─339f9e22-41be-11eb-1ea9-1b2583945bf6
# ╟─6e24a652-41be-11eb-3699-f553c77ff31b
# ╟─33c230c2-41b6-11eb-3626-e3741c798f1b
# ╟─246aba7c-41b6-11eb-03b0-3fe2498642fa
# ╟─8f0b880c-41b6-11eb-1674-a740ecbdf88a
# ╟─cac7e9a4-41b5-11eb-2903-6986af777e41
# ╟─4bb6a13c-41d3-11eb-036d-3528e31d7668
# ╟─7ff1d5a8-41dc-11eb-330e-47864080ac5c
# ╟─c204a204-41dc-11eb-0bed-57edfd530122
# ╟─5437f18c-41d6-11eb-2724-7ba6de5b892c
# ╟─df2887cc-41d9-11eb-022e-0d70b44296b7
# ╟─84f8da0c-41d6-11eb-2617-1143f5dbf53f
# ╟─8fc46eba-41d6-11eb-2cf5-3d6e2d3f7f3d
# ╟─6ca6020c-41dd-11eb-2d8f-316c599b2a1f
# ╟─ed48dba8-41ee-11eb-0a6e-a79198da629f
# ╟─2098b5ce-41e9-11eb-2d68-a56b52a114fa
# ╟─48e54722-41e9-11eb-0938-af78a0f6770a
# ╟─31988b6a-41e9-11eb-33e2-d59ff1e77477
# ╟─58d75242-41e9-11eb-08f2-2b370a268a87
# ╟─d86b02c2-41ee-11eb-3bc0-b1e33a80922f
# ╟─49e61a86-45de-11eb-224d-d1ad42f92225
