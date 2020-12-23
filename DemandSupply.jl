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
	Pkg.add([
		"PlutoUI",
		"Plots",
		])

	using PlutoUI
	using Plots
	gr()
end

# ╔═╡ de91c494-41bc-11eb-3d49-6d14bfde3453
md"""
# Microeconomics - Simulated
Ayush Goel

Here, I want to try and make simulations to get a feel for how the microeconomics principles actually work, and also turn a few knobs to see how that impacts the market. This simulation is interactive (not in the html version), so you can change the values using the interactive elements and see the market play out.
"""

# ╔═╡ bb89659a-41de-11eb-0956-2d9707f79ae3
md"""
The first task is to generate the supply and demand curves. On this webpage, the supply and demand curves will only represent the limit prices for consumers and producers. This means that a consumer will never go higher than their corresponding price on the demand curve, and a producer will never go lower than their corresponding price on the supply curve. The individual prices will be represented with dots (shown in the simulations below).

For now, let's assume that the price of the good varies from $0 - $1. For the demand curve, we can simply generate random numers between 0 and 1 (with equal probability) and then sort them in descending order. For the supply curve, we do the same but sort it in ascending order. This should give us a representative market along with appropriate curves.

The slider below controls the number of producers = number of consumers in the market. 100 means that there are 100 producers and 100 consumers. A larger market size will better show what economics models predict.
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

# ╔═╡ 3124e682-41bd-11eb-001a-6d6ce348f0b1
md""" ## Market Equilibrium

This is the first main concept learnt in microeconomics. The equilibrium is where the demand curve intersects the supply curve, leading to an equilibrium price and quantity. But consumers and producers aren't born with the right price in mind. They have different expectations of the price, and are only limited by the curves. Hence, we need the principle of the invisible hand, which essentially states that an unseen force moves the entire free market economy to reach the equilibrium. 

Let's actually see this in action. Here are the rules:

1. Consumers and Producers have their own prices (which are different from the curves). These represent the expectations they have for the right price.
2. If a consumer and producer meet, they will compare their prices (not the curve values), and if the consumer can pay more than the producer wants, the transaction occurs.
3. If a transaction occurs in the above way, then consumers decrease their prices (expectations) since they got a deal easily, and producers increase their prices (expectations) since they also got a deal too easily.
4. If the consumer has a lower price than the producer, but is still able to pay (based on the curve) enough money, then they do some bargaining and the trade still occurs. However, this time, the producer decreases his price (expectation) since he had to bargain to get a deal, and the consumer increases his price (expectation) also since he had to bargain to get a deal.
5. If a producer is not able to make a trade in a day, then they decrease their price, since it is too high for consumers.
6. If a consumer is not able to make a trade in a day, then they increase their price, since it is too low for producers.

Now let's allow the producers and consumers to start trading. Control the speed of the simulation using the dial below. 
"""

# ╔═╡ 1d007b74-415b-11eb-1795-77f7221ae017
md""" Simulation Speed $(@bind timesteps Clock(0.1))"""

# ╔═╡ 55965e12-41ac-11eb-2bc6-e5c3d4cef731
begin
	cons_expectations = clamp.(consumers .- abs.((0.2 .* rand(length(consumers)))), 0, 10)
	prod_expectations = clamp.(producers .+ abs.((0.2 .* rand(length(producers)))), 0, 10)
	println("")
end

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
If it ran right (which it should have, if it didn't, allow it to run for some more time. Try changing the speed to 0.1 to make it go faster), then you should have seen that all of the consumers and producers participating should have had their prices move towards the market price or equilibrium (right where the demand and supply curve intersect)! This is the invisible hand in practice. Everyone had random prices in mind, but after trading and updating the prices they had, everyone reached the same market price.
"""

# ╔═╡ 6e24a652-41be-11eb-3699-f553c77ff31b
md"""



## Taxes

Now let's add a tax to the mix. The slider below will allow you to control the amount of tax. This will be an indirect specific tax, and will be levied on the consumers. Thus, once a trade happens, the consumer will lose the tax amount, so would naturally want a higher price from consumers.

The green line is the supply curve shifted after tax.
"""

# ╔═╡ 33c230c2-41b6-11eb-3626-e3741c798f1b
md""" Tax Amount $(@bind tax Slider(0:0.01:0.25, show_value=true))"""

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
If you let the simulation run for some time, you can see that the consumer and producer prices have diverged (exactly by the amount of the tax), which is exactly what is predicted by economics principles. Also try changing the tax after the new equilibrium is reached, and you can see how the consumers and producers adjust to the new equilibrium

Another thing to note is that the total market surplus has decreased from before (check the graph above and compare it to this one). This is also what is expected from economic theory. As the amount of tax levied is increased, the total surplus will also decrease.

This shows why producers and consumers get different prices and how they actually stabilize in a real market situation.
"""

# ╔═╡ 7ff1d5a8-41dc-11eb-330e-47864080ac5c
md"""
## Price Floors
"""

# ╔═╡ c204a204-41dc-11eb-0bed-57edfd530122
md"""
Now let's try implementing Price Floors. The logic here is going to be simple. Trading will continue on as it was before, but will have one resitriction: if the consumer price is not more than the price floor, then the trade will not occur.

Another subtle point is that in product markets the government generally comes in and buys the surplus quantity. Implementing that is simple: if a producer is not able to make a trade, but its price is less than the floor, then the goverment will buy it, and they won't have the penalty of not selling anything. But if the price is more than the floor, then the government won't help.

Below is the slider for the price floor (which corresponds to the green line of the graph). You can change it and watch the simulation adapt.
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
First thing we notice is that as long as the price floor is below the equilibrium price, nothing happens. This is because the minimum price at which a product is being sold is still higher than the floor. It gets more interesting when the floor is above market price.

After a price floor, you notice that less consumers (orange dots) are participating in a trade, which is because they can't afford the good after the floor. This leads to a decrease in consumer surplus. On the other hand, more blue dots are able to participate (seen from how the entire green line is filled with dots) which is because the government buys the surplus created from the price floor. 

Either way, the total market surplus still decreases, which is again what microeconomics suggests.

So we can see that so far, all of our simulations fall in line with microeconomics principles, which goes to show how good of a model Demand and Supply is.
"""

# ╔═╡ ed48dba8-41ee-11eb-0a6e-a79198da629f
md"""
## Price Ceiling

Price Ceiling will have a similar logic as price floors, except now the producers can't expect a price higher than the price ceiling. Here, we will assume no other government intervention (the government doesn't fullfill the shortage).

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
Once again, we notice that if the price ceil is above market price, then nothing significant happens. But if we lower it below market price, it becomes much better.

Side Note: The simulation sometimes breaks for very low values of price ceil (<10) as there are not enough producers left for the simulation to be accurate anymore.

We see that a larger number of consumers rush to the price ceil, and that causes a shortage. Also, fewer producers are not able to sell the product, so the producer surplus decreases.
"""

# ╔═╡ Cell order:
# ╟─de91c494-41bc-11eb-3d49-6d14bfde3453
# ╟─9cdd996e-4154-11eb-0d80-43c01f6a93b0
# ╟─bb89659a-41de-11eb-0956-2d9707f79ae3
# ╟─3a84b6fc-415a-11eb-39e9-17acd55bab74
# ╟─ca3c0d9e-4154-11eb-11bf-a9b0a3a48040
# ╟─02e816ee-415a-11eb-0250-4bd6a5f6cb4a
# ╟─3124e682-41bd-11eb-001a-6d6ce348f0b1
# ╟─1d007b74-415b-11eb-1795-77f7221ae017
# ╟─55965e12-41ac-11eb-2bc6-e5c3d4cef731
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
