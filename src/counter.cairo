#[starknet::interface]
trait ICounter<T> {
    fn get_counter(self: @T) -> u32;
    fn increase_counter( ref self: T);
}




#[starknet::contract]
pub mod Counter {
    use kill_switch::IKillSwitchDispatcherTrait;
    use super::{ICounter,ICounterDispatcher,ICounterDispatcherTrait};
    use kill_switch::IKillSwitchDispatcher;
    use starknet::ContractAddress;
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);


    #[storage]
    struct Storage {
        counter : u32,
        kill_switch: IKillSwitchDispatcher,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterIncreased : CounterIncreased,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct CounterIncreased {
        #[key]
        counter: u32,   
    }
    
    #[constructor]
    fn constructor(ref self: ContractState,input: u32,initial_owner: ContractAddress, kill_switch_address: ContractAddress){
        self.counter.write(input);
        let dispatcher = IKillSwitchDispatcher{contract_address: kill_switch_address};
        self.kill_switch.write(dispatcher);
        self.ownable.initializer(initial_owner);

    }
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;
    #[abi(embed_v0)]
    impl ICounterImpl of ICounter<ContractState>{
        fn get_counter(self: @ContractState) -> u32 {
            self.counter.read()
        }
        fn increase_counter( ref self: ContractState) {
            self.ownable.assert_only_owner();
            let kill_switch = self.kill_switch.read();
            if(kill_switch.is_active()==false){
                self.counter.write(self.counter.read()+1);
                self.emit(CounterIncreased{counter: self.counter.read()})
            }
            
            assert!(!kill_switch.is_active(), "Kill Switch is actived");
            
           
        }

    }
}