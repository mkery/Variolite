'use babel';

import AtomicTaroView from './atomic-taro-view';
import { CompositeDisposable } from 'atom';

export default {

  atomicTaroView: null,
  modalPanel: null,
  subscriptions: null,

  activate(state) {
    this.atomicTaroView = new AtomicTaroView(state.atomicTaroViewState);
    this.modalPanel = atom.workspace.addModalPanel({
      item: this.atomicTaroView.getElement(),
      visible: false
    });

    // Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    this.subscriptions = new CompositeDisposable();

    // Register command that toggles this view
    this.subscriptions.add(atom.commands.add('atom-workspace', {
      'atomic-taro:toggle': () => this.toggle()
    }));
  },

  deactivate() {
    this.modalPanel.destroy();
    this.subscriptions.dispose();
    this.atomicTaroView.destroy();
  },

  serialize() {
    return {
      atomicTaroViewState: this.atomicTaroView.serialize()
    };
  },

  toggle() {
    console.log('AtomicTaro was toggled!');
    return (
      this.modalPanel.isVisible() ?
      this.modalPanel.hide() :
      this.modalPanel.show()
    );
  }

};
