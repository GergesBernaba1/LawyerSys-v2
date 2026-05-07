import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qadaya_lawyersys/features/consultations/bloc/consultations_event.dart';
import 'package:qadaya_lawyersys/features/consultations/bloc/consultations_state.dart';
import 'package:qadaya_lawyersys/features/consultations/repositories/consultations_repository.dart';

class ConsultationsBloc extends Bloc<ConsultationsEvent, ConsultationsState> {

  ConsultationsBloc({required this.consultationsRepository}) : super(ConsultationsInitial()) {
    on<LoadConsultations>(_onLoad);
    on<RefreshConsultations>(_onRefresh);
    on<SearchConsultations>(_onSearch);
    on<SelectConsultation>(_onSelect);
    on<CreateConsultation>(_onCreate);
    on<UpdateConsultation>(_onUpdate);
    on<DeleteConsultation>(_onDelete);
  }
  final ConsultationsRepository consultationsRepository;

  Future<void> _onLoad(LoadConsultations event, Emitter<ConsultationsState> emit) async {
    emit(ConsultationsLoading());
    try {
      final consultations = await consultationsRepository.getConsultations();
      emit(ConsultationsLoaded(consultations));
    } catch (e) {
      emit(ConsultationsError(e.toString()));
    }
  }

  Future<void> _onRefresh(RefreshConsultations event, Emitter<ConsultationsState> emit) async {
    try {
      final consultations = await consultationsRepository.getConsultations();
      emit(ConsultationsLoaded(consultations));
    } catch (e) {
      emit(ConsultationsError(e.toString()));
    }
  }

  Future<void> _onSearch(SearchConsultations event, Emitter<ConsultationsState> emit) async {
    emit(ConsultationsLoading());
    try {
      final consultations = await consultationsRepository.searchConsultations(event.query);
      emit(ConsultationsLoaded(consultations));
    } catch (e) {
      emit(ConsultationsError(e.toString()));
    }
  }

  Future<void> _onSelect(SelectConsultation event, Emitter<ConsultationsState> emit) async {
    emit(ConsultationsLoading());
    try {
      final consultation = await consultationsRepository.getConsultationById(event.consultationId);
      if (consultation != null) {
        emit(ConsultationDetailLoaded(consultation));
      } else {
        emit(ConsultationsError('Consultation not found'));
      }
    } catch (e) {
      emit(ConsultationsError(e.toString()));
    }
  }

  Future<void> _onCreate(CreateConsultation event, Emitter<ConsultationsState> emit) async {
    emit(ConsultationsLoading());
    try {
      final created = await consultationsRepository.createConsultation(event.consultation);
      emit(ConsultationOperationSuccess('Consultation created: ${created.subject}'));
      final consultations = await consultationsRepository.getConsultations();
      emit(ConsultationsLoaded(consultations));
    } catch (e) {
      emit(ConsultationsError(e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateConsultation event, Emitter<ConsultationsState> emit) async {
    emit(ConsultationsLoading());
    try {
      final updated = await consultationsRepository.updateConsultation(event.consultation);
      emit(ConsultationOperationSuccess('Consultation updated: ${updated.subject}'));
      final consultations = await consultationsRepository.getConsultations();
      emit(ConsultationsLoaded(consultations));
    } catch (e) {
      emit(ConsultationsError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteConsultation event, Emitter<ConsultationsState> emit) async {
    emit(ConsultationsLoading());
    try {
      await consultationsRepository.deleteConsultation(event.consultationId);
      emit(ConsultationOperationSuccess('Consultation deleted'));
      final consultations = await consultationsRepository.getConsultations();
      emit(ConsultationsLoaded(consultations));
    } catch (e) {
      emit(ConsultationsError(e.toString()));
    }
  }
}
