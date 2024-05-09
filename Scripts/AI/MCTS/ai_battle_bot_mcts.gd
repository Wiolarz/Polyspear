class_name AIBattleBotMCTS
extends ExampleBot


class MCTSNode:
	var reward: float
	var visits: int
	
	var parent: MCTSNode
	var children: Array[MCTSNode]
	var moves: Array
	var playout: BattleManager
	
	func uct() -> float:
		const coeff = sqrt(2)
		return reward/visits + coeff * sqrt(log(parent.visits)/visits)
	
	#func is_explored() -> bool:

	
var root: MCTSNode

func select(node: MCTSNode = self.root) -> MCTSNode:
	for i: MCTSNode in node.children:
		if not i.is_explored():
			return i
	return node.children.map(func(x): return x.uct()).max()
 
func expand(node: MCTSNode):
	pass

func simulate():
	pass

func backpropagate():
	pass

func iterate():
	var node = select()
	expand(node)
	

func play_move() -> void:
	super.play_move()

	root = MCTSNode.new()
	root.playout = BM.cloned()
	
	var moves = AIHelpers.get_all_legal_moves(me, root.playout).back()
	root.playout.perform_ai_move(moves)

