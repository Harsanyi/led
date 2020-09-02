package tool;

class EntityTool extends Tool<Int> {
	public var curEntityDef(get,never) : Null<led.def.EntityDef>;

	public function new() {
		super();

		if( curEntityDef==null && project.defs.entities.length>0 )
			selectValue( project.defs.entities[0].uid );
	}

	inline function get_curEntityDef() return project.defs.getEntityDef(getSelectedValue());

	override function selectValue(v:Int) {
		super.selectValue(v);
	}

	override function canEdit():Bool {
		return super.canEdit() && getSelectedValue()>=0;
	}

	override function isPicking(m:MouseCoords):Bool {
		var e = getGenericLevelElementAt(m, curLayerInstance);
		if( e!=null )
			return true;
		else
			return super.isPicking(m);
	}

	override function getDefaultValue():Int{
		if( project.defs.entities.length>0 )
			return project.defs.entities[0].uid;
		else
			return -1;
	}

	function getPlacementX(m:MouseCoords) {
		return snapToGrid()
			? M.round( ( m.cx + curEntityDef.pivotX ) * curLayerInstance.def.gridSize )
			: m.levelX;
	}

	function getPlacementY(m:MouseCoords) {
		return snapToGrid()
			? M.round( ( m.cy + curEntityDef.pivotY ) * curLayerInstance.def.gridSize )
			: m.levelY;
	}

	override function updateCursor(m:MouseCoords) {
		super.updateCursor(m);

		if( curEntityDef==null )
			editor.cursor.set(None);
		else if( isRunning() && curMode==Remove )
			editor.cursor.set( Eraser(m.levelX,m.levelY) );
		else if( curLevel.inBounds(m.levelX, m.levelY) )
			editor.cursor.set( Entity(curLayerInstance, curEntityDef, getPlacementX(m), getPlacementY(m)) );
		else
			editor.cursor.set(None);
	}


	override function startUsing(m:MouseCoords, buttonId:Int) {
		super.startUsing(m, buttonId);

		switch curMode {
			case null, PanView:
			case Add:
				if( curLevel.inBounds(m.levelX, m.levelY) ) {
					var ei = curLayerInstance.createEntityInstance(curEntityDef);
					if( ei==null )
						N.error("Max per level reached!");
					else {
						ei.x = getPlacementX(m);
						ei.y = getPlacementY(m);
						editor.setSelection( Entity(curLayerInstance, ei) );
						onEditAnything();
						curMode = Move;
					}
				}

			case Remove:
				removeAnyEntityAt(m);

			case Move:
		}
	}

	function removeAnyEntityAt(m:MouseCoords) {
		var ge = getGenericLevelElementAt(m, curLayerInstance);
		switch ge {
			case Entity(curLayerInstance, instance):
				curLayerInstance.removeEntityInstance(instance);
				return true;

			case _:
		}

		return false;
	}

	function getPickedEntityInstance() : Null<led.inst.EntityInstance> {
		switch editor.selection {
			case null, IntGrid(_), Tile(_):
				return null;

			case Entity(curLayerInstance, instance):
				return instance;
		}
	}

	override function useAt(m:MouseCoords) {
		super.useAt(m);

		switch curMode {
			case null, PanView:
			case Add:

			case Remove:
				if( removeAnyEntityAt(m) )
					return true;

			case Move:
				if( moveStarted ) {
					var ei = getPickedEntityInstance();
					var oldX = ei.x;
					var oldY = ei.y;
					ei.x = getPlacementX(m);
					ei.y = getPlacementY(m);
					editor.setSelection( Entity(curLayerInstance, ei) );
					return oldX!=ei.x || oldY!=ei.y;
				}
		}

		return false;
	}

	override function onHistorySaving() {
		super.onHistorySaving();

		if( curMode==Move ) {
			var ei = getPickedEntityInstance();
			if( ei!=null )
				editor.curLevelHistory.setLastStateBounds( ei.left, ei.top, ei.def.width, ei.def.height );
		}
	}


	override function useOnRectangle(left:Int, right:Int, top:Int, bottom:Int) {
		super.useOnRectangle(left, right, top, bottom);
		return false;
		// editor.ge.emit(LayerInstanceChanged);
	}


	override function createToolPalette():ui.ToolPalette {
		return new ui.palette.EntityPalette(this);
	}
}